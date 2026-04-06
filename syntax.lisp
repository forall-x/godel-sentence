;;;; syntax.lisp - Syntax representation and DAG Encoding
(unless (fboundp 'core-loaded) (load "core.lisp"))

(defun get-var-idx (var-name)
  (or (ignore-errors (parse-integer (remove-if-not #'digit-char-p var-name)))
      (sxhash var-name)))

(defun ast-to-dag (ast &optional (memo (make-hash-table :test 'equal)))
  "Converts an AST into a construction sequence (list of nodes). 
    Each node is (Tag LeftIdx RightIdx) where indices refer to previous nodes in the sequence."
  (let ((cached (gethash ast memo)))
    (if cached
        (values cached nil)
        (cond
          ((integerp ast)
           (if (= ast 0)
               (ast-to-dag 'zero memo)
               (if (evenp ast)
                   (multiple-value-bind (h-idx h-seq) (ast-to-dag (/ ast 2) memo)
                     (let ((idx (hash-table-count memo)))
                       (setf (gethash ast memo) idx)
                       (values idx (append h-seq (list (list 4 h-idx h-idx))))))
                   (multiple-value-bind (p-idx p-seq) (ast-to-dag (1- ast) memo)
                     (let ((idx (hash-table-count memo)))
                       (setf (gethash ast memo) idx)
                       (values idx (append p-seq (list (list 3 p-idx 0)))))))))
          ((stringp ast)
           (ast-to-dag (list 'var ast) memo))
          ((symbolp ast)
           (if (eq ast 'zero)
               (let ((idx (hash-table-count memo)))
                 (setf (gethash ast memo) idx)
                 (values idx (list (list 1 0 0))))
               (ast-to-dag (list 'var (symbol-name ast)) memo)))
          ((and (listp ast) (eq (car ast) 'numeral))
           (ast-to-dag (cadr ast) memo))
          ((and (listp ast) (eq (car ast) 'var))
           (let ((idx (hash-table-count memo))
                 (v-idx (get-var-idx (cadr ast))))
             (setf (gethash ast memo) idx)
             (values idx (list (list 2 v-idx 0)))))
          ((listp ast)
           (multiple-value-bind (left-idx left-seq) (ast-to-dag (cadr ast) memo)
             (multiple-value-bind (right-idx right-seq) (if (caddr ast) (ast-to-dag (caddr ast) memo) (values 0 nil))
               (let* ((tag (case (car ast)
                             (succ 3) (add 4) (mul 5) (eq 6) (not 7) (and 8) (or 9) (implies 10) (forall 11) (exists 12)))
                      (idx (hash-table-count memo)))
                 (setf (gethash ast memo) idx)
                 (values idx (append left-seq right-seq (list (list tag left-idx right-idx))))))))
          (t (error "Unknown AST: ~S" ast))))))

(defun flatten-ast-dag (ast)
  (multiple-value-bind (final-idx seq) (ast-to-dag ast)
    (declare (ignore final-idx))
    seq))

(defparameter *gn-cache* (make-hash-table :test 'equal))

(defun count-nodes-dag (ast)
  (length (flatten-ast-dag ast)))

(defun pack-node-dag (tag l r)
  "Packs (Tag, L, R) into a 60-bit integer: [Tag:8][L:28][R:28]"
  (logior (ash (logand tag #xFF) 56)
          (ash (logand l #xFFFFFFF) 28)
          (logand r #xFFFFFFF)))

(defun get-gn (ast)
  "Calculates the Godel number using the Fixed-Width Block Encoding.
   Block 0: Sequence Length L
   Block 1..L: Node (Tag, LeftIdx, RightIdx)"
  (let ((cached (gethash ast *gn-cache*)))
    (if cached
        cached
        (setf (gethash ast *gn-cache*)
              (let* ((dag (flatten-ast-dag ast))
                     (len (length dag))
                     (sum len)) ;; Block 0 is Length
                (loop for (tag l r) in dag
                      for i from 1 do ;; Nodes start at Block 1
                  (let ((node-val (+ (ash tag 56) (ash l 28) r)))
                    (setf sum (+ sum (ash node-val (* i 60))))))
                sum)))))

(defun syntax-loaded () t)
