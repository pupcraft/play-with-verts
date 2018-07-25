(in-package #:play-with-verts)

;;------------------------------------------------------------

;; https://learnopengl.com/Advanced-Lighting/Gamma-Correction
;;
;; See fxaa.lisp for the fragment shader where we are applying
;; the gamma correction. Also see assets.lisp for where we now
;; load textures in :srgb8-alpha8

;;------------------------------------------------------------

(defvar *last-time* (get-internal-real-time))

(defvar *scene-fbo* nil)
(defvar *scene-sampler* nil)
(defvar *scene-depth-sampler* nil)

(defun reset ()
  (setf (clear-color) (v! 0.2 0.2 0.2 0))
  (setf *things* nil)
  ;;(make-ground)
  (make-box (v! 0 0 0) (v! 40 1 40))
  (make-box (v! 0 15 -20) (v! 30 30 1))
  (when *scene-fbo*
    (free *scene-fbo*))
  (setf *scene-fbo*
        (make-fbo (list 0 :element-type :rgba16f) :d))
  (setf *scene-sampler*
        (sample (attachment-tex *scene-fbo* 0)))
  (setf *scene-depth-sampler*
        (sample (attachment-tex *scene-fbo* :d)))
  (when *lights*
    (free *lights*)
    (free *lights-arr*))

  (let* ((light-data (make-c-array nil :dimensions 1
                                  :element-type 'light-set))
         (set (aref-c light-data 0))
         (plights (light-set-plights set)))

    (setf (light-set-count set) 2)

    (setf (aref-c plights 0) (list (v! 0 5 -18)
                                   (v! 1 1 1)
                                   1300.0)
          (aref-c plights 1) (list (v! 0 1 10)
                                   (v! 1 1 1)
                                   1200.0))

    (setf *lights-arr* (make-gpu-array light-data)
          *lights* (make-ubo *lights-arr* 'light-set))))

(defun game-step ()
  (let* ((now (get-internal-real-time))
         (delta (* (- now *last-time*) 0.001))
         (delta (if (> delta 0.16) 0.00001 delta)))
    (setf *last-time* now)

    ;; update camera
    (update *current-camera* delta)

    ;; set the position of our viewport
    (setf (resolution (current-viewport))
          (surface-resolution (current-surface)))

    ;; draw stuff
    (with-fbo-bound (*scene-fbo*)
      (clear-fbo *scene-fbo*)
      (loop :for thing :in *things* :do
           (update thing delta)
           (draw *current-camera* thing)))

    (as-frame
      (fxaa3-pass *scene-sampler*))

    (decay-events)))


(def-simple-main-loop play (:on-start #'reset)
  (game-step))


;; (sdl2-game-controller-db:load-db)
;; (defvar *pad* (sdl2:game-controller-open 0))
;; (skitter.sdl2:enable-background-joystick-events)
