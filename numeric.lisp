;;;; numeric.lisp - Arithmetization utilities and compact numeral generation
(unless (fboundp 'core-loaded) (load "core.lisp"))

(defun numeral (n)
  "Returns a unary numeral AST for n."
  (if (zerop n)
      'zero
      (list 'succ (numeral (1- n)))))


(defun is-numeral (v n counter)
  "Returns a PA formula asserting that the variable with name `v` is equal to the integer `n`.
   Uses positional binary encoding iteratively to avoid stack overflow for large n."
  (if (= n 0)
      (return-from is-numeral (list 'eq (list 'var v) 'zero))
      (if (= n 1)
          (return-from is-numeral (list 'eq (list 'var v) (list 'succ 'zero)))))
  
  (let* ((bits (map 'list (lambda (c) (- (char-code c) (char-code #\0))) (format nil "~B" n)))
         (current-v (fresh-var "ny_" counter))
         (form (list 'eq (list 'var current-v) (list 'succ 'zero))))
    (dolist (bit (cdr bits))
      (let ((prev-v current-v))
        (setf current-v (fresh-var "ny_" counter))
        (let ((double (list 'add (list 'var prev-v) (list 'var prev-v))))
          (setf form (list 'exists prev-v
                           (list 'and form 
                                 (list 'eq (list 'var current-v)
                                           (if (= bit 0) double (list 'succ double)))))))))
    (list 'exists current-v (list 'and form (list 'eq (list 'var v) (list 'var current-v))))))

(defun numeric-loaded () t)

;; (End of numeric.lisp)
