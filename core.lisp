(unless (fboundp 'core-loaded) (defun core-loaded () t))

(defparameter *simplify-numerals* t "If T, to-pa renders numeral nodes as decimal integers.")
(defparameter *simplify-ast-p* t "If T, simplify-ast applies logical and numeric reductions.")

(defun canonize-variables (ast &optional (mapping (make-hash-table :test 'equal)) (start-idx 0))
  "Recursively renames variables in an AST to standard PA syntax (v0, v1, ...).
   - AST: The formula tree to process.
   - MAPPING: A hash-table of {old-name -> new-name}. If provided, these mappings are preserved.
   - START-IDX: The first numeric index to use for renaming (e.g., v0, v1).
   
   This ensures that the final sentence adheres to standard Peano Arithmetic notation and
   produces consistent Gödel numbers regardless of internal variable names."
  (let ((counter start-idx))
    (labels ((get-new-name (name)
               (or (gethash name mapping)
                   (let ((new-name (format nil "v~A" counter)))
                     (incf counter)
                     (setf (gethash name mapping) new-name)
                     new-name)))
             (walk (node)
               (cond
                 ((null node) nil)
                 ;; Variable node: (var "name")
                 ((and (listp node) (eq (car node) 'var))
                  (list 'var (get-new-name (cadr node))))
                 ;; Quantifiers: (forall "var" body) or (exists "var" body)
                 ((and (listp node) (member (car node) '(forall exists)))
                  (let ((new-v (get-new-name (cadr node))))
                    (list (car node) new-v (walk (caddr node)))))
                 ;; Recursive descent for nested lists
                 ((listp node)
                  (mapcar #'walk node))
                 ;; Terminals (numbers, symbols like 'zero)
                 (t node))))
      (walk ast))))

(defun count-unique-vars (ast)
  "Returns the number of unique variables actually present in the AST."
  (let ((vars (make-hash-table :test 'equal)))
    (labels ((walk (node)
               (cond
                 ((null node) nil)
                 ((and (listp node) (eq (car node) 'var))
                  (setf (gethash (cadr node) vars) t))
                 ((and (listp node) (member (car node) '(forall exists)))
                  (setf (gethash (cadr node) vars) t)
                  (walk (caddr node)))
                 ((listp node)
                  (mapcar #'walk node)))))
      (walk ast))
    (hash-table-count vars)))

(defun count-successors (expr)
  "Recursively counts successors of zero. Returns an integer or NIL if not a numeral chain."
  (if (and (consp expr) (eq (car expr) 'succ))
      (let ((inner (count-successors (cadr expr))))
        (if (integerp inner) (1+ inner) nil))
      (if (or (eq expr 'zero) (eq expr 0)
              (and (listp expr) (eq (car expr) 'numeral) (eq (cadr expr) 0)))
          0
          nil)))

(defun is-zero-p (node)
  "Checks if node is structurally 0."
  (let ((num (count-successors node)))
    (and (integerp num) (= num 0))))

(defun is-one-p (node)
  "Checks if node is structurally 1."
  (or (eq node 1)
      (and (listp node) (eq (car node) 'numeral) (eq (cadr node) 1))
      (and (integerp (count-successors node)) (= (count-successors node) 1))))

(defun ensure-term (x)
  "Ensures x is a PA term. If x is an integer, it's wrapped in (numeral x).
   If x is a string, it's wrapped in (var x)."
  (cond
    ((integerp x) (list 'numeral x))
    ((stringp x) (list 'var x))
    (t x)))

(defun simplify-ast (ast)
  "Recursively simplifies the PA AST using logical identities.
   Matches common redundant patterns to produce a more compact and readable sentence:
   - Numeral Compression: S(S(...0...)) -> (numeral n)
   - Additive Identity: 0 + t -> t
   - Multiplicative Identity: 1 * t -> t
   - Multiplication by Zero: 0 * t -> 0"
  (if (not *simplify-ast-p*)
      ast
      (let ((num (count-successors ast)))
        (if num
            (list 'numeral num)
            (cond
              ((null ast) nil)
              ((atom ast) ast)
              ((eq (car ast) 'var) ast)
              ((eq (car ast) 'numeral) ast)  ; Do not simplify inside explicit numeral nodes
              ((member (car ast) '(forall exists))
               (list (car ast) (cadr ast) (simplify-ast (caddr ast))))
              ((eq (car ast) 'not)
               (list 'not (simplify-ast (cadr ast))))
              (t
               (let* ((op (car ast))
                      (args (mapcar #'simplify-ast (cdr ast)))
                      (l (car args))
                      (r (if (cdr args) (cadr args) nil)))
                 (case op
                   (add
                    (cond
                      ((and (listp l) (eq (car l) 'numeral) (listp r) (eq (car r) 'numeral))
                       (list 'numeral (+ (cadr l) (cadr r))))
                      ((is-zero-p l) r)
                      ((is-zero-p r) l)
                      (t (cons 'add args))))
                   (mul
                    (cond
                      ((and (listp l) (eq (car l) 'numeral) (listp r) (eq (car r) 'numeral))
                       (list 'numeral (* (cadr l) (cadr r))))
                      ((is-zero-p l) (ensure-term 0))
                      ((is-zero-p r) (ensure-term 0))
                      ((is-one-p l) r)
                      ((is-one-p r) l)
                      (t (cons 'mul args))))
                   (succ
                    (if (and (listp l) (eq (car l) 'numeral))
                        (list 'numeral (1+ (cadr l)))
                        (cons 'succ args)))
                    (t (cons op args))))))))))

(defun fresh-var (prefix counter)
  (let ((val (incf (symbol-value counter))))
    (format nil "~A~A" prefix val)))

(defun make-forall (var-str formula)
  (list 'forall var-str formula))

(defun make-exists (var-str formula)
  (list 'exists var-str formula))

;; Need to forward declare less-eq for bounds
(defun make-leq (x y counter)
  (let ((z (fresh-var "lz_" counter)))
    (list 'or 
          (list 'exists z 
                (list 'eq (list 'add x (list 'succ (list 'var z))) y))
          (list 'eq x y))))

(defun make-less (x y counter)
  "Formula for x < y which is x + S(z) = y"
  (let ((z (fresh-var "lz_" counter)))
    (list 'exists z (list 'eq (list 'add x (list 'succ (list 'var z))) y))))

(defun make-forall-le (var-str bound formula counter)
  (make-forall var-str (list 'implies (make-leq (list 'var var-str) bound counter) formula)))

(defun make-forall-less (var-str bound formula counter)
  (make-forall var-str (list 'implies (make-less (list 'var var-str) bound counter) formula)))

(defun make-exists-le (var-str bound formula counter)
  (make-exists var-str (list 'and (make-leq (list 'var var-str) bound counter) formula)))

(defun make-pair (c d p)
  "Cantor pairing: 2*p = (c+d)*(c+d+1) + 2*c.
   Assumes c, d, p are PA terms (e.g. (list 'var \"c\"))."
  (let ((sum (list 'add c d)))
    (list 'eq (list 'add p p)
              (list 'add (list 'mul sum (list 'succ sum))
                         (list 'add c c)))))

(defun make-if-then-else (cond then else)
  (list 'and (list 'implies cond then)
             (list 'implies (list 'not cond) else)))

(defun to-ast (f)
  (cond
    ((eq f 'zero) 'zero)
    ((stringp f) (list 'var f))
    ((symbolp f) 
     (if (member f '(zero |ZERO|))
         'zero
         (list 'var (symbol-name f))))
    ((listp f)
     (case (car f)
       (var (list 'var (cadr f)))
       (succ (list 'succ (to-ast (cadr f))))
       (add (list 'add (to-ast (cadr f)) (to-ast (caddr f))))
       (mul (list 'mul (to-ast (cadr f)) (to-ast (caddr f))))
       (eq (list 'eq (to-ast (cadr f)) (to-ast (caddr f))))
       (not (list 'not (to-ast (cadr f))))
       (and (list 'and (to-ast (cadr f)) (to-ast (caddr f))))
       (or (list 'or (to-ast (cadr f)) (to-ast (caddr f))))
       (implies (list 'implies (to-ast (cadr f)) (to-ast (caddr f))))
       (forall (list 'forall (cadr f) (to-ast (caddr f))))
       (exists (list 'exists (cadr f) (to-ast (caddr f))))
       (t (error "Unknown form in to-ast: ~S" f))))
    (t f)))

;;; AST to PA Stringifier

(defun to-pa (expr)
  (cond
    ((eq expr 'zero) "0")
    ((and *simplify-numerals* (count-successors expr)) (format nil "~A" (count-successors expr)))
    ((and (consp expr) (eq (car expr) 'var))
     (cadr expr))
    ((and (consp expr) (eq (car expr) 'succ))
     (let ((inner (to-pa (cadr expr))))
       (if (and (> (length inner) 0) (char= (char inner 0) #\())
           (format nil "S~A" inner)
           (format nil "S(~A)" inner))))
    ((and (consp expr) (eq (car expr) 'add))
     (format nil "(~A+~A)" (to-pa (cadr expr)) (to-pa (caddr expr))))
    ((and (consp expr) (eq (car expr) 'mul))
     (format nil "(~A*~A)" (to-pa (cadr expr)) (to-pa (caddr expr))))
    ((and (consp expr) (eq (car expr) 'eq))
     (format nil "(~A=~A)" (to-pa (cadr expr)) (to-pa (caddr expr))))
    ((and (consp expr) (eq (car expr) 'not))
     (let ((inner (to-pa (cadr expr))))
       (if (and (> (length inner) 0) (char= (char inner 0) #\())
           (format nil "~~~A" inner)
           (format nil "~~(~A)" inner))))
    ((and (consp expr) (eq (car expr) 'and))
     (if (cdddr expr)
         (format nil "(~A&~A)" (to-pa (cadr expr)) (to-pa (cons 'and (cddr expr))))
         (format nil "(~A&~A)" (to-pa (cadr expr)) (to-pa (caddr expr)))))
    ((and (consp expr) (eq (car expr) 'or))
     (if (cdddr expr)
         (format nil "(~Av~A)" (to-pa (cadr expr)) (to-pa (cons 'or (cddr expr))))
         (format nil "(~Av~A)" (to-pa (cadr expr)) (to-pa (caddr expr)))))
    ((and (consp expr) (eq (car expr) 'implies))
     (format nil "(~A->~A)" (to-pa (cadr expr)) (to-pa (caddr expr))))
    ((and (consp expr) (eq (car expr) 'forall))
     (format nil "A~A:~A" (cadr expr) (to-pa (caddr expr))))
    ((and (consp expr) (eq (car expr) 'exists))
     (format nil "E~A:~A" (cadr expr) (to-pa (caddr expr))))
    ((and (consp expr) (eq (car expr) 'numeral))
     (format nil "~A" (cadr expr)))
    ((integerp expr)
     (format nil "~A" expr))
    (t (error "Unknown AST node: ~S" expr))))

(defun to-latex (expr)
  "Converts an AST into a LaTeX representation."
  (cond
    ((eq expr 'zero) "0")
    ((and *simplify-numerals* (count-successors expr)) (format nil "~A" (count-successors expr)))
    ((and (consp expr) (eq (car expr) 'var))
     (let ((name (cadr expr)))
       (if (and (plusp (length name)) (char= (char name 0) #\v))
           (format nil "v_{~A}" (subseq name 1))
           name)))
    ((and (consp expr) (eq (car expr) 'succ))
     (format nil "S(~A)" (to-latex (cadr expr))))
    ((and (consp expr) (eq (car expr) 'add))
     (format nil "(~A + ~A)" (to-latex (cadr expr)) (to-latex (caddr expr))))
    ((and (consp expr) (eq (car expr) 'mul))
     (format nil "(~A \\cdot ~A)" (to-latex (cadr expr)) (to-latex (caddr expr))))
    ((and (consp expr) (eq (car expr) 'eq))
     (format nil "(~A = ~A)" (to-latex (cadr expr)) (to-latex (caddr expr))))
    ((and (consp expr) (eq (car expr) 'not))
     (format nil "\\neg ~A" (to-latex (cadr expr))))
    ((and (consp expr) (eq (car expr) 'and))
     (if (cdddr expr)
         (format nil "(~A \\land ~A)" (to-latex (cadr expr)) (to-latex (cons 'and (cddr expr))))
         (format nil "(~A \\land ~A)" (to-latex (cadr expr)) (to-latex (caddr expr)))))
    ((and (consp expr) (eq (car expr) 'or))
     (if (cdddr expr)
         (format nil "(~A \\lor ~A)" (to-latex (cadr expr)) (to-latex (cons 'or (cddr expr))))
         (format nil "(~A \\lor ~A)" (to-latex (cadr expr)) (to-latex (caddr expr)))))
    ((and (consp expr) (eq (car expr) 'implies))
     (format nil "(~A \\to ~A)" (to-latex (cadr expr)) (to-latex (caddr expr))))
    ((and (consp expr) (eq (car expr) 'forall))
     (let ((var (cadr expr)))
       (format nil "\\forall v_{~A} ~A" (if (char= (char var 0) #\v) (subseq var 1) var) (to-latex (caddr expr)))))
    ((and (consp expr) (eq (car expr) 'exists))
     (let ((var (cadr expr)))
       (format nil "\\exists v_{~A} ~A" (if (char= (char var 0) #\v) (subseq var 1) var) (to-latex (caddr expr)))))
    ((and (consp expr) (eq (car expr) 'numeral))
     (format nil "\\seqsplit{~A}" (cadr expr)))
    ((integerp expr)
     (format nil "\\seqsplit{~A}" expr))
    (t (error "Unknown AST node or corrupted AST: ~S" expr))))

(defun flatten (x)
  (cond ((null x) nil)
        ((atom x) (list x))
        (t (append (flatten (car x)) (flatten (cdr x))))))

(defun core-loaded () t)
