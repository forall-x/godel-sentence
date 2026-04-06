;;;; test_core.lisp - Tests for foundations

(unless (fboundp 'test-helper-loaded) (load "test_helper.lisp"))
(unless (fboundp 'core-loaded) (load "core.lisp"))

(deftest test-to-ast
  (qa-assert-equal '(eq (var "x") (var "y")) (to-ast '(eq "x" "y")))
  (qa-assert-equal '(eq (var "x") zero) (to-ast '(eq "x" zero)))
  (qa-assert-equal '(forall "x" (eq (var "x") (var "x"))) (to-ast '(forall "x" (eq "x" "x")))))

(deftest test-to-pa
  (qa-assert-equal "(x=y)" (to-pa '(eq (var "x") (var "y"))))
  (qa-assert-equal "S(x)" (to-pa '(succ (var "x"))))
  (qa-assert-equal "(x+y)" (to-pa '(add (var "x") (var "y"))))
  (qa-assert-equal "~(x=0)" (to-pa '(not (eq (var "x") zero))))
  (qa-assert-equal "Ax:(x=x)" (to-pa '(forall "x" (eq (var "x") (var "x"))))))

(defvar *test-cnt* 0)
(deftest test-fresh-var
  (setf *test-cnt* 100)
  (qa-assert-equal "v_101" (fresh-var "v_" '*test-cnt*))
  (qa-assert-equal "v_102" (fresh-var "v_" '*test-cnt*))
  (qa-assert-equal 102 (symbol-value '*test-cnt*)))

(deftest test-make-pair-logic
  (let ((form (make-pair (list 'var "x") (list 'var "y") (list 'var "z"))))
    ;; Structural check
    (qa-assert-equal 'eq (car form))
    (qa-assert-equal 'add (car (cadr form)))))
