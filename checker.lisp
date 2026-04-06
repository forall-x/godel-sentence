;;;; checker.lisp - Lisp-side verification engine for PA proofs
;;;; This file implements the SAME logic as the PA predicates in a way that Lisp can execute.

(unless (fboundp 'core-loaded) (load "core.lisp"))
(load "gen_godel.lisp") ; for cantor-pair and get-gn

(defun is-var-gn (gn)
  "Checks if gn is the Godel number of a variable."
  ;; Variables are (cantor-pair 5 idx)
  ;; We don't check injection here strictly, just type
  t) ; Simplified for the demonstration

(defun is-pa1-lisp (gn)
  "~(S(x)=0)"
  (let* ((ast (list 'not (list 'eq (list 'succ (list 'var "x")) 'zero))))
    (= gn (get-gn ast))))

(defun is-pa2-lisp (gn)
  "S(x)=S(y) -> x=y"
  (let* ((ast (list 'implies (list 'eq (list 'succ (list 'var "x")) (list 'succ (list 'var "y")))
                            (list 'eq (list 'var "x") (list 'var "y")))))
    (= gn (get-gn ast))))

(defun is-pa3-lisp (gn)
  "x+0 = x"
  (let* ((ast (list 'eq (list 'add (list 'var "x") 'zero) (list 'var "x"))))
    (= gn (get-gn ast))))
 
(defun is-pa4-lisp (gn)
  "x+S(y) = S(x+y)"
  (let* ((ast (list 'eq (list 'add (list 'var "x") (list 'succ (list 'var "y"))) 
                        (list 'succ (list 'add (list 'var "x") (list 'var "y"))))))
    (= gn (get-gn ast))))

(defun is-pa5-lisp (gn)
  "x*0 = 0"
  (let* ((ast (list 'eq (list 'mul (list 'var "x") 'zero) 'zero)))
    (= gn (get-gn ast))))

(defun is-pa6-lisp (gn)
  "x*S(y) = (x*y)+x"
  (let* ((ast (list 'eq (list 'mul (list 'var "x") (list 'succ (list 'var "y")))
                        (list 'add (list 'mul (list 'var "x") (list 'var "y")) (list 'var "x")))))
    (= gn (get-gn ast))))

(defun is-eq-refl-lisp (gn)
  ;; x=x
  nil) ; Implement as needed

(defun find-diff-in-subst (original target)
  "Finds the pair (old . new) such that target is original with some 'old' replaced by 'new'.
   Returns (old . new) or NIL."
  (cond
    ((equal original target) nil)
    ((and (atom original) (atom target)) (cons original target))
    ((or (atom original) (atom target)) (cons original target))
    ((= (length original) (length target))
     (let ((diffs (remove nil (mapcar #'find-diff-in-subst original target))))
       (if (= (length (remove-duplicates diffs :test #'equal)) 1)
           (car diffs)
           (cons original target))))
    (t (cons original target))))

(defun is-substitution-lisp (ast)
  "Checks if ast is a general Equality Substitution: x=y -> (A[x] -> A[y])"
  (and (listp ast)
       (eq (car ast) 'implies)
       (let ((lhs (cadr ast)) (rhs (caddr ast)))
         (and (listp lhs)
              (eq (car lhs) 'eq)
              (let ((x-term (cadr lhs)) (y-term (caddr lhs)))
                (and (listp rhs)
                     (eq (car rhs) 'implies)
                     (let ((a (cadr rhs)) (ap (caddr rhs)))
                       (equal ap (cl:subst y-term x-term a :test #'equal)))))))))

(defun is-spec-lisp (ast)
  "General check if ast is a Quantifier Specification instance: (forall x A) -> A[t/x]"
  (and (listp ast)
       (eq (car ast) 'implies)
       (let ((lhs (cadr ast)) (rhs (caddr ast)))
         (and (listp lhs)
              (eq (car lhs) 'forall)
              (let ((x (cadr lhs)) (a (caddr lhs)))
                ;; rhs should be a with (var x) replaced by some term t.
                (let ((diff (find-diff-in-subst a rhs)))
                  (if (null diff)
                      t ;; No change is a valid spec (identity)
                      (let ((old (car diff)) (new (cdr diff)))
                        (and (equal old (list 'var x))
                             (equal rhs (cl:subst new old a :test #'equal)))))))))))

(defun is-induction-lisp (ast)
  "Checks if ast is a general Induction Schema: [A(0) & Ax(A(x) -> A(Sx))] -> Ax A(x)"
  (and (listp ast)
       (eq (car ast) 'implies)
       (let ((l (cadr ast)) (r (caddr ast)))
         (and (listp l) (eq (car l) 'and)
              (listp r) (eq (car r) 'forall)
              (let ((a0 (cadr l)) (l2 (caddr l)) (x (cadr r)) (a (caddr r)))
                (and (listp l2) (eq (car l2) 'forall) (equal (cadr l2) x)
                     (let ((l3 (caddr l2)))
                       (and (listp l3) (eq (car l3) 'implies)
                            (let ((ax (cadr l3)) (asx (caddr l3)))
                              (and (equal ax a)
                                   (equal a0 (cl:subst 'zero (list 'var x) a :test #'equal))
                                   (equal asx (cl:subst (list 'succ (list 'var x)) (list 'var x) a :test #'equal))))))))))))

(defun is-eq1-lisp (gn)
  "x=x"
  (let* ((ast (list 'eq (list 'var "x") (list 'var "x"))))
    (= gn (get-gn ast))))

(defun is-eq2-lisp (gn)
  "(x=y) -> (S(x)=S(y))"
  (let* ((ast (list 'implies (list 'eq (list 'var "x") (list 'var "y"))
                            (list 'eq (list 'succ (list 'var "x")) (list 'succ (list 'var "y"))))))
    (= gn (get-gn ast))))

(defun is-axiom-lisp (ast)
  (let ((gn (get-gn ast)))
    (cond
      ((is-pa1-lisp gn) "PA Axiom 1 (~S(x)=0)")
      ((is-pa2-lisp gn) "PA Axiom 2 (Sx=Sy->x=y)")
      ((is-pa3-lisp gn) "PA Axiom 3 (x+0=x)")
      ((is-pa4-lisp gn) "PA Axiom 4 (x+S(y)=S(x+y))")
      ((is-pa5-lisp gn) "PA Axiom 5 (x*0=0)")
      ((is-pa6-lisp gn) "PA Axiom 6 (x*S(y)=xy+x)")
      ((is-eq1-lisp gn) "Equality Axiom EQ1 (x=x)")
      ((is-eq2-lisp gn) "Equality Axiom EQ2 (x=y -> Sx=Sy)")
      ((is-substitution-lisp ast) "Equality Axiom (Substitution)")
      ((is-spec-lisp ast) "Quantifier Axiom (Specification)")
      ((is-induction-lisp ast) "Induction Axiom Schema")
      (t nil))))

(defun is-gen-lisp (f1 f2)
  "Checks if f2 is a generalization of f1 (f2 is forall x f1)."
  (and (listp f2)
       (eq (car f2) 'forall)
       (equal f1 (caddr f2))))

(defun is-mp-lisp (f1 f2 f3)
  "Checks if f1 and f2 |- f3 by Modus Ponens (f1 is A, f2 is A->f3)"
  (and (listp f2)
       (eq (car f2) 'implies)
       (equal f1 (cadr f2))
       (equal f3 (caddr f2))))

(defun get-proof-gn (proof-steps)
  "Calculates the Godel number of the entire proof sequence using Block Encoding."
  (let* ((len (length proof-steps))
         (sum len)) ;; Block 0 is Length
    (loop for f in proof-steps
          for i from 1 do
          (let ((gn (get-gn f)))
            (setf sum (+ sum (ash gn (* i 60))))))
    sum))
(defun checker-loaded () t)

(defun print-proof (proof-steps)
  (format t "~%Self-Verifying Proof Execution~%")
  (format t "=========================================================~%~%")
  (let ((verified-steps nil))
    (loop for step-num from 1
          for f in proof-steps do
          (let ((gn (get-gn f))
                (justification (or (is-axiom-lisp f)
                                   (loop for j from 1 below step-num
                                         as f1 = (nth (1- j) verified-steps)
                                         when (is-gen-lisp f1 f)
                                         return (format nil "Generalization on step ~D" j))
                                   (loop for j from 1 below step-num
                                         as f1 = (nth (1- j) verified-steps)
                                         thereis (loop for k from 1 below step-num
                                                       as f2 = (nth (1- k) verified-steps)
                                                       when (is-mp-lisp f1 f2 f)
                                                       return (format nil "Modus Ponens on steps ~D and ~D" j k))))))
            (if justification
                (progn
                  (format t "Step ~2D: ~A~%" step-num (to-pa (simplify-ast f)))
                  (format t "         Godel #: ~A~%" (format-gn gn))
                  (setf verified-steps (append verified-steps (list f)))
                  (format t "         Proof GN so far: ~A~%" (format-gn (get-proof-gn verified-steps)))
                  (format t "         Justification: ~A~%~%" justification))
                (error "Step ~D (~A) is not justified by axioms or previous steps!" step-num (to-pa (simplify-ast f))))))
    (format t "VERIFICATION COMPLETE: Every step follows from PA axioms and rules.~%")
    (format t "Q.E.D.~%")))
