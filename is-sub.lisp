;;;; is-sub.lisp - Predicate IsSub(f, x, y, f_prime) for Block Encoding

(defun is-sub-pa (f x y f_prime counter)
  "Formula for f_prime = f[y/x] in Block Encoding.
   Reads length from Block 0 and iterates through blocks 1 to L."
  (let ((j (fresh-var "j_" counter))
        (len (fresh-var "len_" counter))
        (blk (fresh-var "blk_" counter))
        (blk_prime (fresh-var "blk_prime_" counter))
        (tag (fresh-var "tag_" counter))
        (l (fresh-var "l_" counter))
        (l_prime (fresh-var "l_prime_" counter))
        (r (fresh-var "r_" counter))
        (size60 60)
        (size28 28)
        (p28 (fresh-var "p28_" counter))
        (p56 (fresh-var "p56_" counter)))
    (list 'exists len
      (list 'exists p28
        (list 'exists p56 
          (list 'and 
            (make-block-segment f 'zero (list 'var len) size60 counter)
            (make-block-segment f_prime 'zero (list 'var len) size60 counter)
            (make-pow2 (list 'var p28) (list 'numeral size28) counter)
            (make-pow2 (list 'var p56) (list 'mul (list 'succ (list 'succ 'zero)) (list 'numeral size28)) counter)
            (make-forall-le j (list 'var len)
              (list 'implies 
                (list 'and 
                  (make-less 'zero (list 'var j) counter)
                  (make-less (list 'var j) (list 'succ (list 'var len)) counter)
                )
                (list 'exists blk
                  (list 'exists blk_prime 
                    (list 'and 
                      (make-block-segment f (list 'var j) (list 'var blk) size60 counter)
                      (make-block-segment f_prime (list 'var j) (list 'var blk_prime) size60 counter)
                      (list 'exists tag
                        (list 'exists l
                          (list 'exists l_prime
                            (list 'exists r 
                              (list 'and 
                                (list 'eq (list 'var blk) 
                                          (list 'add (list 'mul (list 'var tag) (list 'var p56)) 
                                                     (list 'add (list 'mul (list 'var l) (list 'var p28)) (list 'var r))))
                                (list 'eq (list 'var blk_prime) 
                                          (list 'add (list 'mul (list 'var tag) (list 'var p56)) 
                                                     (list 'add (list 'mul (list 'var l_prime) (list 'var p28)) (list 'var r))))
                                (make-if-then-else (list 'and (list 'eq (list 'var tag) (list 'succ (list 'succ 'zero)))
                                                                (list 'eq (list 'var l) (ensure-term x)))
                                                   (list 'eq (list 'var l_prime) (ensure-term y))
                                                   (list 'eq (list 'var l_prime) (list 'var l)))
                              )
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
(defun is-sub-loaded () t)
