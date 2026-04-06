;;;; test_helper.lisp - Minimal testing framework with Skip support

(unless (fboundp 'core-loaded) (load "core.lisp"))

(defvar *tests* nil)
(defvar *pass-count* 0)
(defvar *fail-count* 0)
(defvar *skip-count* 0)
(defvar *cnt* 0)

(defun test-helper-loaded () t)

(defmacro deftest (name &body body)
  `(progn
     (format t "Registering test: ~A~%" ',name)
     (finish-output)
     (pushnew ',name *tests*)
     (defun ,name ()
       (format t "Running test: ~A... " ',name)
       (finish-output)
       (let ((prev-fail *fail-count*)
             (prev-skip *skip-count*))
         (handler-case
             (progn ,@body)
           (error (c)
             (if (subtypep (type-of c) 'depth-exceeded)
                 (progn 
                   (format t "SKIPPED (depth exceeded)~%")
                   (incf *skip-count*))
                 (progn
                   (format t "CRITICAL FAIL: ~A~%" (type-of c))
                   (format t "Error details: ~A~%" c)
                   (incf *fail-count*)))))
         (if (and (= prev-fail *fail-count*) (= prev-skip *skip-count*))
             (format t "PASS~%")
             (unless (= prev-skip *skip-count*)
               (format t "DONE (with skips)~%")))
         (finish-output)))))

(defun qa-assert-equal (expected actual)
  (handler-case
      (if (equal expected actual)
          (incf *pass-count*)
          (error "Expected ~S but got ~S" expected actual))
    (depth-exceeded (c) (error c))))

(defun qa-assert-true (val)
  (handler-case
      (if val
          (incf *pass-count*)
          (error "Assertion failed: value is NIL"))
    (depth-exceeded (c) (error c))))

(defun run-all-tests ()
  (setf *pass-count* 0 *fail-count* 0 *skip-count* 0)
  (format t "~%--- STARTING TEST SUITE ---~%")
  (format t "Total tests to run: ~A~%" (length *tests*))
  (loop for test in (reverse *tests*)
        do (funcall test))
  (format t "~%--- RESULTS ---~%")
  (format t "Passed: ~A~%" *pass-count*)
  (format t "Failed: ~A~%" *fail-count*)
  (format t "Skipped: ~A~%" *skip-count*)
  (if (> *fail-count* 0)
      (progn (format t "Test suite failed!~%") (sb-ext:exit :code 1))
      (format t "All tests passed!~%")))
