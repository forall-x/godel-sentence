;;;; is-ast.lisp - AST verification for Fixed-Width Block Encoding
(unless (fboundp 'core-loaded) (load "core.lisp"))
(unless (fboundp 'syntax-loaded) (load "syntax.lisp"))

(defun is-ast-node-pa (tag l r j counter)
  "Checks if node (tag, l, r) at index j is valid. 
   l and r must be indices less than j."
  (declare (ignore r))
  (list 'or 
        (list 'eq tag (list 'succ 'zero)) ; ZERO
        (list 'eq tag (list 'succ (list 'succ 'zero))) ; VAR
        (list 'and (make-less l j counter)
                   (list 'or (list 'eq tag (list 'succ (list 'succ (list 'succ 'zero)))) ; SUCC
                             (list 'eq tag (list 'succ (list 'succ (list 'succ (list 'succ 'zero))))) ; ADD
                             (list 'eq tag (list 'succ (list 'succ (list 'succ (list 'succ (list 'succ 'zero)))))))) ; ...
        ))

(defun is-ast-pa (gn counter)
  "gn is a DAG construction sequence."
  (let ((j (fresh-var "j_" counter))
        (len (fresh-var "len_" counter))
        (block (fresh-var "blk_" counter))
        (tag (fresh-var "tag_" counter))
        (l (fresh-var "l_" counter))
        (r (fresh-var "r_" counter))
        (size60 60)
        (size28 28)
        (p28 (fresh-var "p28_" counter))
        (p56 (fresh-var "p56_" counter)))
    (list 'exists len
      (list 'exists p28
        (list 'exists p56
          (list 'and 
                (make-block-segment gn 'zero (list 'var len) size60 counter)
                (make-pow2 (list 'var p28) (list 'numeral size28) counter)
                (make-pow2 (list 'var p56) (list 'mul (list 'succ (list 'succ 'zero)) (list 'numeral size28)) counter)
                (make-forall-le j (list 'var len) 
                   (list 'implies 
                     (list 'and (make-less 'zero (list 'var j) counter)
                                (make-less (list 'var j) (list 'succ (list 'var len)) counter))
                     (list 'exists block 
                        (list 'and 
                          (make-block-segment gn (list 'var j) (list 'var block) size60 counter)
                          (list 'exists tag
                            (list 'exists l
                              (list 'exists r 
                                (list 'and 
                                  (list 'eq (list 'var block) 
                                            (list 'add (list 'mul (list 'var tag) (list 'var p56)) 
                                                       (list 'add (list 'mul (list 'var l) (list 'var p28)) (list 'var r))))
                                  (is-ast-node-pa (list 'var tag) (list 'var l) (list 'var r) (list 'var j) counter)
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
(defun is-ast-loaded () t)
