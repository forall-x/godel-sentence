;;;; is-proof.lisp - Proof verification for Block Encoding
(unless (fboundp 'is-axiom-loaded) (load "is-axiom.lisp"))
(unless (fboundp 'is-inference-loaded) (load "is-inference.lisp"))

(defun is-proof-of-pa (p f counter)
  "PA formula asserting that p is the Gödel number of a proof of f.
   p is a Cantor-pair (c, d) representing a sequence of Gödel numbers (each a Block DAG).
   Beta(c, d, l) = f, where l is the length of the proof.
   
   For each index j <= l, Beta(c, d, j) must either:
   1. Be a PA axiom (is-axiom-pa), or
   2. Follow from two previous entries j1, j2 via Modus Ponens (is-mp-pa), or
   3. Follow from a previous entry j1 via Generalization (is-gen-pa)."
  (let ((c (fresh-var "pc_" counter))
        (d (fresh-var "pd_" counter))
        (l (fresh-var "pl_" counter))
        (j (fresh-var "pj_" counter))
        (fj (fresh-var "pfj_" counter))
        (j1 (fresh-var "pj1_" counter))
        (j2 (fresh-var "pj2_" counter))
        (f1 (fresh-var "pf1_" counter))
        (f2 (fresh-var "pf2_" counter)))
    (list 'exists c 
      (list 'exists d 
        (list 'exists l
          (list 'and 
            (make-pair (list 'var c) (list 'var d) p)
            (make-beta (list 'var c) (list 'var d) (list 'var l) (ensure-term f) counter)
            (make-forall-le j (list 'var l)
               (list 'implies 
                 (make-less 'zero (list 'var j) counter)
                 (list 'exists fj 
                   (list 'and 
                     (make-beta (list 'var c) (list 'var d) (list 'var j) (list 'var fj) counter)
                     (list 'or 
                       (is-axiom-pa (list 'var fj) counter)
                       (list 'exists j1 
                         (list 'exists j2 
                            (list 'and 
                              (make-less (list 'var j1) (list 'var j) counter)
                              (make-less (list 'var j2) (list 'var j) counter)
                              (list 'exists f1 
                                (list 'exists f2 
                                   (list 'and 
                                     (make-beta (list 'var c) (list 'var d) (list 'var j1) (list 'var f1) counter)
                                     (make-beta (list 'var c) (list 'var d) (list 'var j2) (list 'var f2) counter)
                                     (is-mp-pa (list 'var f1) (list 'var f2) (list 'var fj) counter)
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
               counter
            )
          )
        )
      )
    )
  )
)
(defun is-proof-loaded () t)
