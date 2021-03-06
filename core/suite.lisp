(in-package #:cl-user)
(defpackage #:rove/core/suite
  (:use #:cl
        #:rove/core/assertion
        #:rove/core/test
        #:rove/core/stats)
  (:import-from #:rove/core/result
                #:test-name)
  (:import-from #:rove/core/suite/package
                #:*execute-assertions*)
  (:export #:run-system-tests
           #:*last-suite-report*
           #:*rove-standard-output*
           #:*rove-error-output*))
(in-package #:rove/core/suite)

(defvar *last-suite-report* nil)

(defparameter *rove-standard-output* nil)
(defparameter *rove-error-output* nil)

(defun system-dependencies (system)
  (unless (typep system 'asdf:package-inferred-system)
    (error "~A isn't a package-inferred-system" system))

  (let* ((deps (asdf:component-sideway-dependencies system))
         (deps
           (remove-if-not (lambda (system)
                            (typep system 'asdf:package-inferred-system))
                          (mapcar #'asdf:find-system deps))))
    (remove-duplicates
     (append (mapcan #'system-dependencies deps)
             deps)
     :from-end t)))

;; XXX: Almost same as SYSTEM-DEPENDENCIES
(defun system-components (system)
  (unless (typep system 'asdf:package-inferred-system)
    (error "~A isn't a package-inferred-system" system))

  (let* ((deps (asdf:component-sideway-dependencies system))
         (deps
           (remove-if-not (lambda (dep-system)
                            (and (typep dep-system 'asdf:package-inferred-system)
                                 (system-component-p system dep-system)))
                          (mapcar #'asdf:find-system deps))))
    (remove-duplicates
     (append (mapcan #'system-components deps)
             deps)
     :from-end t)))

(defun system-component-p (system component)
  (let* ((system-name (asdf:component-name system))
         (comp-name (asdf:component-name component)))
    (and (< (length system-name) (length comp-name))
         (string= system-name
                  comp-name
                  :end2 (length system-name)))))

(defun run-system-tests (system-designator)
  (let ((system (asdf:find-system system-designator)))
    (unless (typep system 'asdf:package-inferred-system)
      (error "~A isn't a package-inferred-system" system))

    (let ((*stats* (or *stats*
                       (make-instance 'stats)))
          (*execute-assertions* nil)
          (*standard-output* (or *rove-standard-output*
                                 *standard-output*))
          (*error-output* (or *rove-error-output*
                              *error-output*)))

      (let* ((package-name (string-upcase (asdf:component-name system)))
             (package (find-package package-name)))

        #+quicklisp (ql:quickload (asdf:component-name system) :silent t)
        #-quicklisp (asdf:load-system (asdf:component-name system))
        (unless package
          (setf package (find-package package-name)))

        ;; Loading dependencies beforehand
        (let ((deps (system-components system)))
          (dolist (dep deps)
            (let* ((package-name (string-upcase (asdf:component-name dep)))
                   (package (find-package package-name)))
              (when (and package
                         (package-tests package))
                (format t "~&;; testing '~(~A~)'~%" (package-name package))
                (run-package-tests package)))))

        (when (and package
                   (package-tests package))
          (format t "~&;; testing '~(~A~)'~%" (package-name package))
          (run-package-tests package)))

      (let ((passed (coerce (stats-passed *stats*) 'list))
            (failed (coerce (stats-failed *stats*) 'list)))

        (format t "~2&Summary:~%")
        (if failed
            (format t "  ~D file~:*~P failed.~{~%    - ~A~}~%"
                    (length failed)
                    (mapcar #'test-name failed))
            (format t "  All ~D file~:*~P passed.~%"
                    (length passed)))

        (setf *last-suite-report*
              (list (= 0 (length (stats-failed *stats*)))
                    passed
                    failed))
        (apply #'values *last-suite-report*)))))
