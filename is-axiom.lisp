(unless (fboundp 'syntax-loaded) (load "syntax.lisp"))
(unless (fboundp 'is-sub-loaded) (load "is-sub.lisp"))

(defvar *pa-axioms* 
  (list 
    '(not (eq (succ "x") zero)) ; PA1
    '(implies (eq (succ "x") (succ "y")) (eq (var "x") (var "y"))) ; PA2
    '(eq (add "x" zero) (var "x")) ; PA3
    '(eq (add "x" (succ "y")) (succ (add "x" "y"))) ; PA4
    '(eq (mul "x" zero) zero) ; PA5
    '(eq (mul "x" (succ "y")) (add (mul "x" "y") "x")) ; PA6
    '(eq (var "x") (var "x")) ; Equality Refl (EQ1)
    '(implies (eq (var "x") (var "y")) (eq (succ "x") (succ "y"))) ; Successor Congruence (EQ2)
  ))

(defun make-multi-or (forms)
  (if (null (cdr forms))
      (car forms)
      (list 'or (car forms) (make-multi-or (cdr forms)))))

(defun is-spec-pa (f counter)
  "Checks if f is an instance of (Ax A) -> A[t/x].
   Root of f is IMPLIES(10), left child is FORALL(11), right child is A'."
  (let ((blk_f (fresh-var "blk_f" counter))
        (blk_l (fresh-var "blk_l" counter))
        (blk_r (fresh-var "blk_r" counter))
        (blk_a (fresh-var "blk_a" counter))
        (x_gn (fresh-var "x_gn" counter))
        (t_gn (fresh-var "t_gn" counter))
        (len_f (fresh-var "len_f" counter))
        (len_l (fresh-var "len_l" counter)))
    (list 'exists len_f
      (list 'exists len_l
        (list 'exists blk_f
          (list 'exists blk_l
            (list 'exists blk_r
              (list 'exists blk_a
                (list 'exists x_gn
                  (list 'exists t_gn
                    (list 'and
                      ;; f is IMPLIES(10, L, R)
                      (make-block-segment f 'zero (list 'var len_f) 60 counter)
                      (make-block-segment f (list 'var len_f) (list 'var blk_f) 60 counter)
                      (list 'eq (list 'var blk_f) (list 'add (list 'mul (list 'numeral 10) (list 'numeral (expt 2 56)))
                                                            (list 'add (list 'mul (list 'var blk_l) (list 'numeral (expt 2 28))) (list 'var blk_r))))
                      ;; L is FORALL(11, X, A)
                      (make-block-segment (list 'var blk_l) 'zero (list 'var len_l) 60 counter)
                      (make-block-segment (list 'var blk_l) (list 'var len_l) (list 'var blk_l) 60 counter) ; reuse blk_l as the node
                      (list 'eq (list 'var blk_l) (list 'add (list 'mul (list 'numeral 11) (list 'numeral (expt 2 56)))
                                                            (list 'add (list 'mul (list 'var x_gn) (list 'numeral (expt 2 28))) (list 'var blk_a))))
                      ;; R is A[t/x]
                      (is-sub-pa (list 'var blk_a) (list 'var x_gn) (list 'var t_gn) (list 'var blk_r) counter)
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  )
)

(defun is-equality-subst-pa (f counter)
  "Checks if f is x=y -> (A[x] -> A[y]).
   Root: IMPLIES(10, EQ(5, x, y), IMPLIES(10, A, A')). "
  (let ((blk_f (fresh-var "blk_f" counter))
        (blk_l (fresh-var "blk_l" counter))
        (blk_r (fresh-var "blk_r" counter))
        (blk_eq (fresh-var "blk_eq" counter))
        (blk_impl (fresh-var "blk_impl" counter))
        (x_gn (fresh-var "x_gn" counter))
        (y_gn (fresh-var "y_gn" counter))
        (a_gn (fresh-var "a_gn" counter))
        (ap_gn (fresh-var "ap_gn" counter))
        (len_f (fresh-var "len_f" counter)))
    (list 'exists len_f
      (list 'exists blk_f
        (list 'exists blk_l
          (list 'exists blk_r
            (list 'exists blk_eq
              (list 'exists x_gn
                (list 'exists y_gn
                  (list 'exists blk_impl
                    (list 'exists a_gn
                      (list 'exists ap_gn
                        (list 'and
                          ;; f: IMPLIES(L, R)
                          (make-block-segment f 'zero (list 'var len_f) 60 counter)
                          (make-block-segment f (list 'var len_f) (list 'var blk_f) 60 counter)
                          (list 'eq (list 'var blk_f) (list 'add (list 'mul (list 'numeral 10) (list 'numeral (expt 2 56)))
                                                                (list 'add (list 'mul (list 'var blk_l) (list 'numeral (expt 2 28))) (list 'var blk_r))))
                          ;; L: EQ(x, y)
                          (make-block-segment (list 'var blk_l) 'zero (list 'numeral 0) 60 counter) ; wait, EQ is usually a node
                          (make-block-segment (list 'var blk_l) (list 'numeral 1) (list 'var blk_eq) 60 counter)
                          (list 'eq (list 'var blk_eq) (list 'add (list 'mul (list 'numeral 5) (list 'numeral (expt 2 56)))
                                                                (list 'add (list 'mul (list 'var x_gn) (list 'numeral (expt 2 28))) (list 'var y_gn))))
                          ;; R: IMPLIES(A, A')
                          (make-block-segment (list 'var blk_r) (list 'numeral 1) (list 'var blk_impl) 60 counter) ; simplified access
                          (list 'eq (list 'var blk_impl) (list 'add (list 'mul (list 'numeral 10) (list 'numeral (expt 2 56)))
                                                                (list 'add (list 'mul (list 'var a_gn) (list 'numeral (expt 2 28))) (list 'var ap_gn))))
                          ;; A' = A[y/x]
                          (is-sub-pa (list 'var a_gn) (list 'var x_gn) (list 'var y_gn) (list 'var ap_gn) counter)
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  )
)

(defun is-induction-pa (f counter)
  "Checks if f matches the induction schema: [A(0) & Ax(A(x) -> A(Sx))] -> Ax A(x).
   Structure:
   - Root f: IMPLIES(10, L, R)
   - R: FORALL(11, x, A)
   - L: AND(8, A0, L2)
   - L2: FORALL(11, x, L3)
   - L3: IMPLIES(10, Ax, ASx)
   - Condition: A0 = A[0/x] and ASx = A[Sx/x]."
  (let ((blk_f (fresh-var "blk_f" counter))
        (blk_l (fresh-var "blk_l" counter))
        (blk_r (fresh-var "blk_r" counter))
        (blk_a (fresh-var "blk_a" counter))
        (blk_a0 (fresh-var "blk_a0" counter))
        (blk_l2 (fresh-var "blk_l2" counter))
        (blk_l3 (fresh-var "blk_l3" counter))
        (blk_ax (fresh-var "blk_ax" counter))
        (blk_asx (fresh-var "blk_asx" counter))
        (x_gn (fresh-var "x_gn" counter))
        (gn_sx (fresh-var "gn_sx" counter))
        (len_f (fresh-var "len_f" counter)))
    (list 'exists len_f
      (list 'exists blk_f
        (list 'exists blk_l
          (list 'exists blk_r
            (list 'exists x_gn
              (list 'exists blk_a
                (list 'exists blk_a0
                  (list 'exists blk_l2
                    (list 'exists blk_l3
                      (list 'exists blk_ax
                        (list 'exists blk_asx
                          (list 'exists gn_sx
                            (list 'and
                              ;; f: IMPLIES(L, R)
                              (make-block-segment f 'zero (list 'var len_f) 60 counter)
                              (make-block-segment f (list 'var len_f) (list 'var blk_f) 60 counter)
                              (list 'eq (list 'var blk_f) (list 'add (list 'mul (list 'numeral 10) (list 'numeral (expt 2 56)))
                                                                    (list 'add (list 'mul (list 'var blk_l) (list 'numeral (expt 2 28))) (list 'var blk_r))))
                              ;; R: FORALL(x, A)
                              (make-block-segment (list 'var blk_r) (list 'numeral 1) (list 'var blk_r) 60 counter) ; blk access
                              (list 'eq (list 'var blk_r) (list 'add (list 'mul (list 'numeral 11) (list 'numeral (expt 2 56)))
                                                                    (list 'add (list 'mul (list 'var x_gn) (list 'numeral (expt 2 28))) (list 'var blk_a))))
                              ;; L: AND(A0, L2)
                              (make-block-segment (list 'var blk_l) (list 'numeral 1) (list 'var blk_l) 60 counter)
                              (list 'eq (list 'var blk_l) (list 'add (list 'mul (list 'numeral 8) (list 'numeral (expt 2 56)))
                                                                    (list 'add (list 'mul (list 'var blk_a0) (list 'numeral (expt 2 28))) (list 'var blk_l2))))
                              ;; L2: FORALL(x, L3)
                              (make-block-segment (list 'var blk_l2) (list 'numeral 1) (list 'var blk_l2) 60 counter)
                              (list 'eq (list 'var blk_l2) (list 'add (list 'mul (list 'numeral 11) (list 'numeral (expt 2 56)))
                                                                    (list 'add (list 'mul (list 'var x_gn) (list 'numeral (expt 2 28))) (list 'var blk_l3))))
                              ;; L3: IMPLIES(Ax, ASx)
                              (make-block-segment (list 'var blk_l3) (list 'numeral 1) (list 'var blk_l3) 60 counter)
                              (list 'eq (list 'var blk_l3) (list 'add (list 'mul (list 'numeral 10) (list 'numeral (expt 2 56)))
                                                                    (list 'add (list 'mul (list 'var blk_ax) (list 'numeral (expt 2 28))) (list 'var blk_asx))))
                              ;; Conditions:
                              (list 'eq (list 'var blk_ax) (list 'var blk_a))
                              (is-sub-pa (list 'var blk_a) (list 'var x_gn) (list 'numeral (get-gn 'zero)) (list 'var blk_a0) counter)
                              (list 'eq (list 'var gn_sx) (list 'add (list 'mul (list 'numeral 3) (list 'numeral (expt 2 56)))
                                                                      (list 'add (list 'mul (list 'var x_gn) (list 'numeral (expt 2 28))) (list 'numeral 0))))
                              (is-sub-pa (list 'var blk_a) (list 'var x_gn) (list 'var gn_sx) (list 'var blk_asx) counter)
                            )
                          )
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  )
)

(defun is-axiom-pa (gn-term counter)
    (let* ((gn-axioms (mapcar #'get-gn *pa-axioms*))
           (fixed-axioms (loop for val in gn-axioms 
                               collect (list 'eq (ensure-term gn-term) (list 'numeral val)))))
    (list 'or (make-multi-or fixed-axioms)
              (list 'or (is-spec-pa gn-term counter)
                        (list 'or (is-equality-subst-pa gn-term counter)
                                  (is-induction-pa gn-term counter))))))

(defun is-axiom-loaded () t)
