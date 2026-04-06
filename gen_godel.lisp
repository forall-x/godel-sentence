;;;; gen_godel.lisp - Final Godel sentence generation with Block Encoding

(unless (fboundp 'core-loaded) (load "core.lisp"))
(unless (fboundp 'numeric-loaded) (load "numeric.lisp"))
(unless (fboundp 'sequence-loaded) (load "sequence.lisp"))
(unless (fboundp 'syntax-loaded) (load "syntax.lisp"))
(unless (fboundp 'is-free-loaded) (load "is-free.lisp"))
(unless (fboundp 'is-sub-loaded) (load "is-sub.lisp"))
(unless (fboundp 'is-proof-loaded) (load "is-proof.lisp"))
(unless (fboundp 'is-ast-loaded) (load "is-ast.lisp"))
(unless (fboundp 'is-inference-loaded) (load "is-inference.lisp"))
(unless (fboundp 'is-diag-loaded) (load "is-diag.lisp"))
(unless (fboundp 'is-axiom-loaded) (load "is-axiom.lisp"))

(defvar *counter* 0)

(defun replace-all (string part replacement)
  "Vanilla Common Lisp replace-all (search and replace)."
  (with-output-to-string (out)
    (loop with part-len = (length part)
          for old-pos = 0 then (+ pos part-len)
          for pos = (search part string :start2 old-pos)
          do (write-string string out :start old-pos :end (or pos (length string)))
          when pos do (write-string replacement out)
          while pos)))

(defun make-godel-sentence ()
  "The main entry point for constructing the PA Gödel sentence.
    The construction follows the standard diagonal lemma:
    1. Define a predicate PSI(y) = 'y is the Gödel number of a non-provable formula'.
    2. Construct ALPHA(x) = 'PSI(diag(x))'.
    3. Let n = GN(ALPHA).
    4. The Gödel sentence G is ALPHA(n) = PSI(diag(n)).
    
    By construction, PA |- G <-> PSI(GN(G)), which means PA |- G <-> ~Provable(GN(G))."
  (format t "Starting Godel sentence construction (Compact Block Encoding)...~%")
  
  (let* (;; PSI(y) asserts that there is no proof p of the formula represented by y.
         (psi-body (lambda (y-ast) 
                     (list 'not (list 'exists "p" 
                                      (is-proof-of-pa (list 'var "p") y-ast '*counter*)))))
         
         ;; ALPHA(x) represents PSI(sub(x, num(x), x_idx)).
         ;; It asserts 'If I am given my own Gödel number, I am not provable'.
         (alpha-ast (list 'exists "g_prime" 
                           (list 'and (list 'exists "x_diag" (is-diag-pa (list 'var "x") (list 'var "x_diag") '*counter*))
                                      (funcall psi-body (list 'var "g_prime"))))))
    
    (let ((nodes (count-nodes-dag alpha-ast)))
      (format t "  Stage 1: Calculating gn(alpha)... (DAG size: ~A nodes)~%" nodes))
    (finish-output)
    
    (let* ((alpha-mapping (make-hash-table :test 'equal))
           (dummy (setf (gethash "x" alpha-mapping) "v1"))
           ;; Step 1: Simplify and canonize ALPHA to ensure a stable Gödel number.
           ;; We map the free variable "x" to "v1" for the diagonalization.
           (alpha-std (canonize-variables (simplify-ast alpha-ast) alpha-mapping 2))
           (n-val (get-gn alpha-std)))
      (declare (ignore dummy))
      (format t "    gn(alpha) bits: ~A.~%" (integer-length n-val))
      (finish-output)
      
      (format t "  Stage 2: Building Godel sentence...~%")
      (finish-output)
      
      (let* ((nx-var "nx_godel")
             ;; is-numeral(nx, n) asserts that nx is the Gödel number of ALPHA.
             (is-n-form (is-numeral-pa n-val (list 'var nx-var) '*counter*))
             ;; Substitute the free variable "v1" in alpha-std with the numeral-representing variable.
             (alpha-subst (subst (list 'var nx-var) (list 'var "v1") alpha-std :test #'equal))
             ;; G = exists nx (is-numeral(nx, n) & ALPHA(nx))
             (godel-ast (simplify-ast (list 'exists nx-var (list 'and is-n-form alpha-subst))))
             
             ;; Final post-processing: Rename all variables to v0, v1, ...
             (godel-mapping (make-hash-table :test 'equal))
             (dummy2 (setf (gethash nx-var godel-mapping) "v0"))
             (dummy3 (maphash (lambda (k v) (setf (gethash k godel-mapping) v)) alpha-mapping))
             (godel-std (canonize-variables godel-ast godel-mapping 2)))
        (declare (ignore dummy2 dummy3))
        
        (format t "  Godel AST constructed.~%")
        (format t "  Unique variables used: ~A.~%" (count-unique-vars godel-std))
        (finish-output)
        (let ((s (to-pa godel-std)))
          (format t "  Length of Godel Sentence (PA syntax): ~A characters.~%" (length s))
          
          ;; Save the human-readable PA string and machine-readable AST.
          (with-open-file (f "godel.pa" :direction :output :if-exists :supersede)
            (write-string s f))
          (with-open-file (f "godel.ast" :direction :output :if-exists :supersede)
            (format f "~S~%" godel-std))
          
          ;; Load and fill the LaTeX template.
          (let* ((template (with-open-file (stream "godel.tex.template")
                             (let ((data (make-string (file-length stream))))
                               (read-sequence data stream)
                               data)))
                 (gn-str (format nil "~A" n-val))
                 (gn-prefix (subseq gn-str 0 (min (length gn-str) 20)))
                 (gn-bits (format nil "~A" (integer-length n-val)))
                 (gn-pow10 (format nil "~A" (floor (* (integer-length n-val) (log 2 10)))))
                 (formula-latex (to-latex godel-std))
                 
                 (final-tex (replace-all 
                              (replace-all 
                                (replace-all 
                                  (replace-all template "{{GODEL_GN_PREFIX}}" gn-prefix)
                                  "{{GODEL_GN_BITS}}" gn-bits)
                                "{{GODEL_GN_POW10}}" gn-pow10)
                              "{{GODEL_PA_FORMULA}}" formula-latex)))
            
            (with-open-file (f "godel.tex" :direction :output :if-exists :supersede)
              (write-string final-tex f)))

          (format t "  Godel sentence saved to godel.pa.~%")
          (format t "  Godel AST saved to godel.ast.~%")
          (format t "  Godel LaTeX saved to godel.tex.~%"))))))
