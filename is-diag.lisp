;;;; is-diag.lisp - Diagonalization Predicate for Block Encoding
(unless (fboundp 'is-sub-loaded) (load "is-sub.lisp"))

(defun is-numeral-pa (n num_gn counter)
  "PA formula asserting that num_gn is the Gödel number of the numeral n.
   Uses a binary iterative construction: num(2k) = num(k)+num(k), num(2k+1) = S(num(k)+num(k)).
   This allows constructing the numeral for n using O(log n) nodes, 
   which is essential for keeping the Gödel sentence size manageable."
  (let ((c (fresh-var "nc_" counter))
        (d (fresh-var "nd_" counter))
        (l (fresh-var "nl_" counter))
        (j (fresh-var "nj_" counter))
        (nj (fresh-var "nvj_" counter))
        (nj+1 (fresh-var "nvj1_" counter))
        (bj (fresh-var "nbj_" counter)))
    (list 'exists c 
      (list 'exists d 
        (list 'exists l
          (list 'and 
            (make-beta (list 'var c) (list 'var d) 'zero (list 'numeral (get-gn '(succ zero))) counter)
            (make-beta (list 'var c) (list 'var d) (list 'var l) (ensure-term num_gn) counter)
            (make-forall-le j (list 'var l) 
              (list 'implies 
                (make-less (list 'var j) (list 'var l) counter)
                (list 'exists nj 
                  (list 'exists nj+1 
                    (list 'exists bj
                      (list 'and 
                        (make-beta (list 'var c) (list 'var d) (list 'var j) (list 'var nj) counter)
                        (make-beta (list 'var c) (list 'var d) (list 'succ (list 'var j)) (list 'var nj+1) counter)
                        (make-bit-segment-2 n (list 'var j) (list 'var bj) counter)
                        ;; nj+1 = (nj + nj) [+ 1]
                        (make-if-then-else 
                          (list 'eq (list 'var bj) 'zero)
                          (list 'eq (list 'var nj+1) (list 'add (list 'var nj) (list 'var nj)))
                          (list 'eq (list 'var nj+1) (list 'succ (list 'add (list 'var nj) (list 'var nj))))
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

(defun is-diag-pa (x y counter)
  "Constructs a PA formula representing the diagonalization predicate:
   y = diag(x), where diag(x) is the Gödel number of the formula 
   resulting from substituting the numeral for x into the formula with Gödel number x.
   
   Logically: y = x[num(x)/v_x]"
  (let ((nx (fresh-var "nx_" counter))
        (x_var_idx (list 'numeral (get-var-idx "x"))))
    (list 'exists nx 
          (list 'and (is-numeral-pa x (list 'var nx) counter)
                     (is-sub-pa (ensure-term x) (ensure-term x_var_idx) (list 'var nx) y counter)))))
(defun is-diag-loaded () t)
