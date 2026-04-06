;;;; prove_1plus1.lisp - Formal proof of 1+1=2 using the PA verification engine
(unless (fboundp 'checker-loaded) (load "checker.lisp"))
(unless (fboundp 'is-proof-loaded) (load "is-proof.lisp"))

;; Disable simplification for formal transparency in this PA-correctness demo
(setf *simplify-ast-p* nil)
(setf *simplify-numerals* nil)


(defun format-gn (n)
  "Returns a compact string representation of n as a sum of powers of 2."
  (if (zerop n) "0"
      (let ((exponents nil))
        (loop for i from 0
              until (< n (expt 2 i))
              do (when (logbitp i n) (push i exponents)))
        (format nil "~{~A~^ + ~}" 
                (mapcar (lambda (e) (if (zerop e) "1" (format nil "2^~A" e))) 
                        (reverse exponents))))))

(let* ((x "x") (y "y") (zero 'zero) (one (list 'succ 'zero)) (two (list 'succ one))
       ;; The 1+1=2 proof sequence
       (pa4-bare (list 'eq (list 'add (list 'var x) (list 'succ (list 'var y))) (list 'succ (list 'add (list 'var x) (list 'var y)))))
       (pa4-gen-y (list 'forall y pa4-bare))
       (pa4-gen-x (list 'forall x pa4-gen-y))

       (pa4-spec-x (list 'forall y (list 'eq (list 'add one (list 'succ (list 'var y))) (list 'succ (list 'add one (list 'var y))))))
       (pa4-spec-y (list 'eq (list 'add one (list 'succ zero)) (list 'succ (list 'add one zero))))
       
       (pa3-bare (list 'eq (list 'add (list 'var x) zero) (list 'var x)))
       (pa3-gen-x (list 'forall x pa3-bare))
       (pa3-spec (list 'eq (list 'add one zero) one))

       ;; (add one zero) = one -> [(add one one = S(add one zero)) -> (add one one = S(one))]
       (sa (list 'eq (list 'add one one) (list 'succ (list 'add one zero))))
       (sb (list 'eq (list 'add one one) two))
       (sub-axiom (list 'implies (list 'eq (list 'add one zero) one) (list 'implies sa sb)))
       (step7 (list 'implies sa sb))
       (step8 (list 'eq (list 'add one one) two))
       
       ;; The complete sequence (including all needed axioms for Hilbert-style)
       (proof (list pa4-bare                     ; Step 1
                    pa4-gen-y                    ; Step 2
                    pa4-gen-x                    ; Step 3
                    (list 'implies pa4-gen-x pa4-spec-x) ; Step 4 (Axiom Spec)
                    pa4-spec-x                   ; Step 5 (MP 3, 4)
                    (list 'implies pa4-spec-x pa4-spec-y) ; Step 6 (Axiom Spec)
                    pa4-spec-y                   ; Step 7 (MP 5, 6)
                    pa3-bare                     ; Step 8
                    pa3-gen-x                    ; Step 9
                    (list 'implies pa3-gen-x pa3-spec) ; Step 10 (Axiom Spec)
                    pa3-spec                     ; Step 11 (MP 9, 10)
                    sub-axiom                    ; Step 12 (Axiom Eq)
                    step7                        ; Step 13 (MP 11, 12)
                    step8)))                     ; Step 14 (MP 7, 13)

  (setf *simplify-numerals* nil)
  (print-proof proof)
  (setf *simplify-numerals* t)
  
  ;; --- Final Arithmetized Verification ---
  (format t "~%Arithmetizing the Verification Predicate...~%")
  (let* ((gn-s (get-gn step8))
         (gn-p (get-proof-gn proof))
         (cnt '*proof-counter*)
         ;; Create fresh variables for bound targets
         (p_var "PROOF_VAL")
         (s_var "STMT_VAL"))
    (defvar *proof-counter* 1000) ;; Offset from proof steps
    
    ;; 1. Construct numeric predicates for the massive GNs
    (let* ((is-gn-p (is-numeral p_var gn-p cnt))
           (is-gn-s (is-numeral s_var gn-s cnt))
           ;; 2. Construct the proof predicate
           (is-proof (is-proof-of-pa (list 'var p_var) (list 'var s_var) cnt))
           ;; 3. Combine into the mega-formula: E P, S: IsNum(P, gn_p) & IsNum(S, gn_s) & IsProof(P, S)
           (mega-form (list 'exists p_var 
                            (list 'exists s_var 
                                  (list 'and is-gn-p (list 'and is-gn-s is-proof))))))
      
      (format t "=========================================================~%")
      (format t "Formal Arithmetized Verification Predicate Built.~%")
      (format t "Statement GN: ~D bits.~%" (integer-length gn-s))
      (format t "Proof GN:     ~D bits.~%" (integer-length gn-p))
      (format t "Predicate AST Complexity: ~D nested nodes.~%" (length (flatten mega-form)))
      (format t "Resulting PA formula starts with: ~A...~%" (subseq (to-pa is-gn-p) 0 40))
      (format t "Verification predicate successfully generated for use in PA.~%"))))

(sb-ext:quit)
