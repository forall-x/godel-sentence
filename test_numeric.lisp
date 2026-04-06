;;;; test_numeric.lisp - Structural tests for PA numeral arithmetization

(unless (fboundp 'test-helper-loaded) (load "test_helper.lisp"))
(unless (fboundp 'numeric-loaded) (load "numeric.lisp"))

(deftest test-is-numeral-structure
  (let ((form0 (is-numeral "x" 0 '*cnt*))
        (form1 (is-numeral "x" 1 '*cnt*))
        (form2 (is-numeral "x" 2 '*cnt*))
        (form5 (is-numeral "x" 5 '*cnt*)))
    ;; 0: (x=0)
    (qa-assert-equal 'eq (car form0))
    ;; 1: (x=S(0))
    (qa-assert-equal 'eq (car form1))
    ;; 2: (exists current-v (and ...))
    (qa-assert-equal 'exists (car form2))
    ;; 5: (exists ...)
    (qa-assert-equal 'exists (car form5))
    ;; Verify it starts with an existential quantifier for larger numbers
    (qa-assert-true (member 'exists form5))))
