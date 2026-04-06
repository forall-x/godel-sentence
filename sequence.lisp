;;;; sequence.lisp - Beta function and sequence encoding in PA

(unless (fboundp 'core-loaded) (load "core.lisp"))

(defun make-rem (c m x counter)
  "Constructs a PA formula for (c mod m = x).
   Logically: (x < m) AND (exists k such that c = k*m + x)."
  (let ((k (fresh-var "rk_" counter)))
    (list 'and (make-less x m counter)
               (list 'exists k (list 'eq c (list 'add (list 'mul (list 'var k) m) x))))))

(defun make-beta (c d i x counter)
  "Constructs a PA formula for Gödel's Beta function: Beta(c, d, i) = x.
   The Beta function allows encoding arbitrary sequences of numbers in PA
   using only addition and multiplication. 
   It is defined as: c mod (1 + (i + 1) * d) = x."
  (let* ((i+1 (list 'succ i))
         (term (list 'mul i+1 d))
         (m (list 'succ term)))
    (make-rem c m x counter)))

(defun make-pow2 (p i counter)
  "Returns a formula for 2^i = p using Beta function"
  (let ((c (fresh-var "pc_" counter))
        (d (fresh-var "pd_" counter))
        (j (fresh-var "pj_" counter))
        (vj (fresh-var "pv_" counter))
        (vj1 (fresh-var "pv1_" counter)))
    (list 'exists c 
          (list 'exists d 
                (list 'and 
                      (make-beta (list 'var c) (list 'var d) 'zero (list 'succ 'zero) counter)
                      (make-beta (list 'var c) (list 'var d) i p counter)
                      (make-forall-less j i
                                       (list 'exists vj 
                                             (list 'exists vj1
                                                   (list 'and (make-beta (list 'var c) (list 'var d) (list 'var j) (list 'var vj) counter)
                                                              (make-beta (list 'var c) (list 'var d) (list 'succ (list 'var j)) (list 'var vj1) counter)
                                                              (list 'eq (list 'var vj1) (list 'add (list 'var vj) (list 'var vj))))))
                                       counter))))))

(defun make-pow16 (p i counter)
  "Formula for 16^i = p"
  (let ((c (fresh-var "p16c_" counter))
        (d (fresh-var "p16d_" counter))
        (j (fresh-var "p16j_" counter))
        (vj (fresh-var "p16v_" counter))
        (vj1 (fresh-var "p16v1_" counter))
        (sixteen (list 'numeral 16)))
    (list 'exists c 
          (list 'exists d 
                (list 'and 
                      (make-beta (list 'var c) (list 'var d) 'zero (list 'succ 'zero) counter)
                      (make-beta (list 'var c) (list 'var d) i p counter)
                      (make-forall-less j i
                                       (list 'exists vj 
                                             (list 'exists vj1
                                                   (list 'and (make-beta (list 'var c) (list 'var d) (list 'var j) (list 'var vj) counter)
                                                              (make-beta (list 'var c) (list 'var d) (list 'succ (list 'var j)) (list 'var vj1) counter)
                                                              (list 'eq (list 'var vj1) (list 'mul sixteen (list 'var vj))))))
                                       counter))))))

(defun make-bit-segment-2 (n i b counter)
  "Constructs a PA formula asserting that the i-th bit of n is b.
   Uses the power-of-2 decomposition: n = q * (2 * 2^i) + b * 2^i + r, where r < 2^i."
  (let ((p (fresh-var "bits_p_" counter))
        (q (fresh-var "bits_q_" counter))
        (r (fresh-var "bits_r_" counter)))
    (list 'exists p 
          (list 'exists q 
                (list 'exists r 
                      (list 'and 
                            (make-pow2 (list 'var p) i counter)
                            (list 'eq (ensure-term n) (list 'add (list 'mul (list 'var q) (list 'mul (list 'var p) (list 'numeral 2)))
                                                   (list 'add (list 'mul (ensure-term b) (list 'var p))
                                                              (list 'var r))))
                            (make-less (list 'var r) (list 'var p) counter)))))))

(defun make-block-segment (n i val block-size counter)
  "Constructs a PA formula asserting that the i-th block of n is val.
   Each block consists of 'block-size' bits. 
   This is used to index into the sequence of nodes in a Block DAG."
  (let ((p (fresh-var "blks_p_" counter))
        (q (fresh-var "blks_q_" counter))
        (r (fresh-var "blks_r_" counter))
        ;; boundary = 2^(block-size)
        (base (list 'numeral (expt 2 block-size)))
        (block-idx (list 'mul i (list 'numeral block-size))))
    (list 'exists p 
          (list 'exists q 
                (list 'exists r 
                      (list 'and 
                            (make-pow2 (list 'var p) block-idx counter)
                            (list 'eq (ensure-term n) (list 'add (list 'mul (list 'var q) (list 'mul (list 'var p) base))
                                                   (list 'add (list 'mul (ensure-term val) (list 'var p))
                                                              (list 'var r))))
                            (make-less (list 'var r) (list 'var p) counter)))))))


(defun sequence-loaded () t)
