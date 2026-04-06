;;;; test_sequence.lisp - Structural tests for PA sequences and bit-ops

(unless (fboundp 'test-helper-loaded) (load "test_helper.lisp"))
(unless (fboundp 'sequence-loaded) (load "sequence.lisp"))
(load "core.lisp")

(deftest test-make-rem-structure
  (let ((form (make-rem (list 'var "c") (list 'var "m") (list 'var "x") '*cnt*)))
    ;; Check for (and (less x m) (exists k (eq c (add (mul k m) x))))
    (qa-assert-equal 'and (car form))
    (qa-assert-equal 'exists (car (caddr form)))))

(deftest test-make-beta-structure
  (let ((form (make-beta (list 'var "c") (list 'var "d") 'zero (list 'var "x") '*cnt*)))
    ;; Beta is a rem with specific m
    (qa-assert-equal 'and (car form))
    ;; rem's second part is the exists k...
    (qa-assert-equal 'exists (car (caddr form)))))

(deftest test-make-pow2-structure
  (let ((form (make-pow2 (list 'var "p") (list 'var "i") '*cnt*)))
    (qa-assert-equal 'exists (car form))
    ;; exists d
    (qa-assert-equal 'exists (car (caddr form)))))

(deftest test-make-bit-segment-structure
  (let ((form (make-bit-segment-2 (list 'var "n") (list 'var "i") 1 '*cnt*)))
    (qa-assert-equal 'exists (car form))
    ;; Should contain a pow2 somewhere
    (qa-assert-true (member 'exists form))))

(deftest test-make-block-segment-structure
  (let ((form (make-block-segment (list 'var "n") 'zero (list 'numeral 5) 2 '*cnt*)))
    (qa-assert-equal 'exists (car form))))
