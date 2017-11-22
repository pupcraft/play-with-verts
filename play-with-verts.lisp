(in-package #:play-with-verts)

;;------------------------------------------------------------

(defvar *some-sampler* nil)
(defvar *bs* nil)
(defvar *feedback-vec4* nil)
(defvar *feedback-vec2* nil)
(defvar *feedback-fb* nil)
(defvar *tfs* nil)

(defstruct-g fb-data
  (v4 :vec4)
  (v2 :vec2))

(defun reset ()
  (setf *some-sampler* (tex "wat0.png"))
  (setf *bs* (make-buffer-stream nil :primitive :points)))

(defun-g foo ((x :int) (y :int))
  (* x y))

(defun-g simple-vert ((vert :vec2))
  (values ((:feedback 0) (v! vert 0 1))
          (* (* (+ vert (v! 1 1)) 0.5)
             (v! 1 -1))
          ((:feedback 1) (v! 9 9))))

(defparameter *factor* 1f0)

(defun-g blit ((uv :vec2) &uniform (sam :sampler-2d))
  (texture sam uv))

(defun-g tester ()
  (+ 1 2))

(defun-g tester ((x :int))
  (+ 1 2 x))

(defun-g tester ((x :float) &uniform (sam :sampler-2d))
  (values (texture sam (* (v! 1 1) x))
          1
          1.2))

(defpipeline-g blitter ()
  :vertex (simple-vert :vec2)
  :fragment (blit :vec2))

(defun game-step ()
  (setf (viewport-resolution (current-viewport))
        (surface-resolution (current-surface (cepl-context))))
  (as-frame
    (with-transform-feedback (*tfs*)
      (map-g #'blitter (get-quad-stream-v2)
             :sam *some-sampler*))))

(def-simple-main-loop play (:on-start #'reset)
  (game-step))
