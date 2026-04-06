;;;; is-free.lisp - Predicate IsFree(x, f) for Block Encoding

(defun is-free-node-pa (tag l r j sj x-var p28 p56 counter)
  "Checks if node (tag, l, r) at index j has free variable property sj."
  (declare (ignore r j p28 p56))
  (list 'or 
    (list 'and (list 'eq tag (list 'succ 'zero)) (list 'eq sj 'zero))
    (list 'and (list 'eq tag (list 'succ (list 'succ 'zero)))
               (list 'or (list 'and (list 'eq l x-var) (list 'eq sj (list 'succ 'zero)))
                         (list 'and (list 'not (list 'eq l x-var)) (list 'eq sj 'zero))))
    (list 'and (list 'eq tag (list 'succ (list 'succ (list 'succ 'zero))))
               (list 'exists "sa" (list 'and (make-beta (list 'var "sc") (list 'var "sd") l (list 'var "sa") counter)
                                           (list 'eq sj (list 'var "sa")))))))

(defun is-free-pa (x-var gn counter)
  "Checks if variable x-var is free in the DAG-encoded formula gn."
  (let ((sc (fresh-var "sc_" counter))
        (sd (fresh-var "sd_" counter))
        (len (fresh-var "len_" counter))
        (j (fresh-var "j_" counter))
        (sj (fresh-var "sj_" counter))
        (block (fresh-var "blk_" counter))
        (tag (fresh-var "tag_" counter))
        (l (fresh-var "l_" counter))
        (r (fresh-var "r_" counter))
        (size60 60)
        (size28 28)
        (p28 (fresh-var "p28_" counter))
        (p56 (fresh-var "p56_" counter)))
    (list 'exists len
      (list 'exists sc
        (list 'exists sd 
          (list 'exists p28
            (list 'exists p56
              (list 'and 
                (make-block-segment gn 'zero (list 'var len) size60 counter)
                (make-pow2 (list 'var p28) (list 'numeral size28) counter)
                (make-pow2 (list 'var p56) (list 'mul (list 'succ (list 'succ 'zero)) (list 'numeral size28)) counter)
                (make-beta (list 'var sc) (list 'var sd) (list 'var len) (list 'succ 'zero) counter)
                (make-forall-le j (list 'var len)
                  (list 'implies 
                    (list 'and (make-less 'zero (list 'var j) counter)
                               (make-less (list 'var j) (list 'succ (list 'var len)) counter))
                    (list 'exists block
                      (list 'exists sj 
                        (list 'and 
                          (make-block-segment gn (list 'var j) (list 'var block) size60 counter)
                          (make-beta (list 'var sc) (list 'var sd) (list 'var j) (list 'var sj) counter)
                          (list 'exists tag
                            (list 'exists l
                              (list 'exists r 
                                (list 'and 
                                  (list 'eq (list 'var block) 
                                            (list 'add (list 'mul (list 'var tag) (list 'var p56)) 
                                                       (list 'add (list 'mul (list 'var l) (list 'var p28)) (list 'var r))))
                                  (is-free-node-pa (list 'var tag) (list 'var l) (list 'var r) (list 'var j) (list 'var sj) x-var p28 p56 counter)
                                )
                              )
                            )
                          )
                        )
                      )
                    )
                  )
                  counter
                )
              )
            )
          )
        )
      )
    )
  )
)
(defun is-free-loaded () t)
