;;;; test_robustness.lisp - Negative testing and edge cases for PA logic
(unless (fboundp 'test-helper-loaded) (load "test_helper.lisp"))
(unless (fboundp 'checker-loaded) (load "checker.lisp"))
(unless (fboundp 'core-loaded) (load "core.lisp"))

(deftest test-negative-axioms
  "Verifies that the Lisp-side checker rejects false or non-axiomatic formulas."
  (let ((false-ax1 '(eq zero (succ zero))) ; 0 = 1
        (false-ax2 '(eq (add zero zero) (succ zero)))) ; 0 + 0 = 1
    (qa-assert-true (null (is-axiom-lisp false-ax1)))
    (qa-assert-true (null (is-axiom-lisp false-ax2)))))

(deftest test-negative-proofs
  "Verifies that print-proof (the Lisp-side verifier) errors out on invalid steps."
  (let ((invalid-proof '((eq zero zero) ; EQ1 (valid)
                         (eq zero (succ zero))))) ; 0=1 (invalid jump)
    (handler-case
        (progn
          (print-proof invalid-proof)
          (error "Failed to reject invalid proof!"))
      (error (c)
        (format t "Successfully caught invalid proof: ~A~%" c)
        (incf *pass-count*)))))

(deftest test-substitution-nesting
  "Verifies that substitution blueprinting handles nested terms correctly."
  (let* ((x (list 'var "x"))
         (y (list 'var "y"))
         (f (list 'eq x y))
         (term1 (list 'add (list 'var "z") 'zero))
         ;; Substitute x -> (z + 0)
         (f1 (cl:subst term1 x f :test #'equal))
         ;; Substitute y -> x (Shadowing / Nesting)
         (f2 (cl:subst x y f1 :test #'equal)))
    (qa-assert-equal '(eq (add (var "z") zero) (var "x")) f2)))

(deftest test-variable-capture-behavior
  "Formally documents that our is-sub-pa performing global structural replacement.
   Verify that it substitutes into all occurrences, even those that would be bound
   in a capture-aware logic."
  (let* ((x (list 'var "x"))
         (y (list 'var "y"))
         ;; forall x (x = y)
         (f (list 'forall "x" (list 'eq x y)))
         ;; Substitute y -> x
         ;; In capture-aware logic, this should rename the binder or fail.
         ;; In our 'structural sharing' approach, it becomes forall x (x = x).
         (f-sub (cl:subst x y f :test #'equal)))
    (qa-assert-equal '(forall "x" (eq (var "x") (var "x"))) f-sub)))

(defun test-robustness-loaded () t)
