;;;; is-inference.lisp - Rules of Inference for Block Encoding

(defun is-mp-pa (f1 f2 f3 counter)
  "Checks if f1 and f2 |- f3 by Modus Ponens (f2 is f1 -> f3).
   In DAG terms, the root node of f2 must be an IMPLIES(10) with children matching f1 and f3."
  (let ((block (fresh-var "blk_" counter))
        (tag (fresh-var "tag_" counter))
        (l (fresh-var "l_" counter))
        (r (fresh-var "r_" counter))
        (len_f1 (fresh-var "len1_" counter))
        (len_f3 (fresh-var "len3_" counter))
        (len_f2 (fresh-var "len2_" counter)))
    (list 'exists len_f1
      (list 'exists len_f3
        (list 'exists len_f2
          (list 'exists block
            (list 'exists tag
              (list 'exists l
                (list 'exists r 
                  (list 'and 
                    (make-block-segment f1 'zero (list 'var len_f1) 60 counter)
                    (make-block-segment f3 'zero (list 'var len_f3) 60 counter)
                    (make-block-segment f2 'zero (list 'var len_f2) 60 counter)
                    (make-block-segment f2 (list 'var len_f2) (list 'var block) 60 counter)
                    (list 'eq (list 'var block) 
                              (list 'add (list 'mul (list 'var tag) (list 'numeral (expt 2 56))) 
                                         (list 'add (list 'mul (list 'var l) (list 'numeral (expt 2 28))) (list 'var r))))
                    (list 'eq (list 'var tag) (list 'numeral 10))
                    (list 'eq (list 'var l) (ensure-term len_f1))
                    (list 'eq (list 'var r) (ensure-term len_f3))
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

(defun is-gen-pa (f1 f2 counter)
  "Checks if f1 |- f2 by Generalization (f2 is forall x f1).
   Root of f2 must be FORALL(11) with child f1."
  (let ((block (fresh-var "blk_" counter))
        (tag (fresh-var "tag_" counter))
        (l (fresh-var "l_" counter))
        (r (fresh-var "r_" counter))
        (len_f1 (fresh-var "len1_" counter))
        (len_f2 (fresh-var "len2_" counter)))
    (list 'exists len_f1
      (list 'exists len_f2
        (list 'exists block
          (list 'exists tag
            (list 'exists l
              (list 'exists r 
                (list 'and 
                  (make-block-segment f1 'zero (list 'var len_f1) 60 counter)
                  (make-block-segment f2 'zero (list 'var len_f2) 60 counter)
                  (make-block-segment f2 (list 'var len_f2) (list 'var block) 60 counter)
                  (list 'eq (list 'var block) 
                            (list 'add (list 'mul (list 'var tag) (list 'numeral (expt 2 56))) 
                                       (list 'add (list 'mul (list 'var l) (list 'numeral (expt 2 28))) (list 'var r))))
                  (list 'eq (list 'var tag) (list 'numeral 11))
                  (list 'eq (list 'var r) (ensure-term len_f1))
                )
              )
            )
          )
        )
      )
    )
  )
)
(defun is-inference-loaded () t)
