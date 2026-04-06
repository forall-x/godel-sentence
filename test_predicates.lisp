;;;; test_predicates.lisp - Structural tests for PA predicates

(unless (fboundp 'test-helper-loaded) (load "test_helper.lisp"))
(unless (fboundp 'core-loaded) (load "core.lisp"))
(unless (fboundp 'syntax-loaded) (load "syntax.lisp"))
(unless (fboundp 'is-ast-loaded) (load "is-ast.lisp"))
(unless (fboundp 'is-free-loaded) (load "is-free.lisp"))
(unless (fboundp 'is-sub-loaded) (load "is-sub.lisp"))
(unless (fboundp 'is-proof-loaded) (load "is-proof.lisp"))
(unless (fboundp 'is-axiom-loaded) (load "is-axiom.lisp"))
(unless (fboundp 'is-inference-loaded) (load "is-inference.lisp"))
(unless (fboundp 'is-diag-loaded) (load "is-diag.lisp"))

(deftest test-is-ast-structure
  (let* ((gn (get-gn '(eq (var "x") zero)))
         (form (is-ast-pa gn '*cnt*)))
    ;; Formula should be a large conjunction/quantified form
    (qa-assert-true (listp form))
    (qa-assert-true (member (car form) '(and forall exists)))))

(deftest test-is-free-structure
  (let* ((f '(eq (var "x") zero))
         (gn (get-gn f))
         (v-idx (get-var-idx "x"))
         (form (is-free-pa gn v-idx '*cnt*)))
    (qa-assert-true (listp form))))

(deftest test-is-sub-structure
  (let* ((f-orig '(eq (var "x") (var "y")))
         (f-new  '(eq (numeral 5) (var "y")))
         (gn-orig (get-gn f-orig))
         (gn-new  (get-gn f-new))
         (gn-val  (get-gn '(numeral 5)))
         (v-idx (get-var-idx "x"))
         (form (is-sub-pa gn-orig v-idx gn-val gn-new '*cnt*)))
    (qa-assert-true (listp form))))

(deftest test-is-proof-structure
  (let* ((f '(eq zero zero))
         (gn (get-gn f))
         (form (is-proof-of-pa (list 'numeral 100) (list 'numeral gn) '*cnt*)))
    (qa-assert-true (listp form))
    (qa-assert-equal 'exists (car form))))

(deftest test-is-axiom-structure
  (let* ((gn (get-gn '(eq (add (var "x") zero) (var "x"))))
         (form (is-axiom-pa (list 'numeral gn) '*cnt*)))
    ;; Axiom check should be an OR or simple EQ
    (qa-assert-true (member (car form) '(or eq)))))

(deftest test-is-inference-structure
  (let* ((f1 (get-gn '(eq (var "p") (var "p"))))
         (f2 (get-gn '(implies (eq (var "p") (var "p")) (eq (var "q") (var "q")))))
         (f3 (get-gn '(eq (var "q") (var "q"))))
         (form-mp (is-mp-pa (list 'numeral f1) (list 'numeral f2) (list 'numeral f3) '*cnt*))
         (form-gen (is-gen-pa (list 'numeral f1) (list 'numeral f2) '*cnt*)))
    (qa-assert-equal 'exists (car form-mp))
    (qa-assert-equal 'exists (car form-gen))))

(deftest test-is-diag-structure
  (let* ((gn (get-gn '(forall "x" (eq (var "x") zero))))
         (form (is-diag-pa (list 'numeral gn) (list 'var "y") '*cnt*)))
    (qa-assert-equal 'exists (car form))))

(defun test-predicates-loaded () t)
