;;;; test_syntax.lisp - Tests for DAG encoding

(unless (fboundp 'test-helper-loaded) (load "test_helper.lisp"))
(unless (fboundp 'syntax-loaded) (load "syntax.lisp"))

(deftest test-pack-node
  ;; Pack: TAG=3 (SUCC), L=5, R=2
  ;; Bits: TAG(56-59), L(28-55), R(0-27)
  (let ((node (pack-node-dag 3 5 2)))
    (qa-assert-equal 2 (ldb (byte 28 0) node))
    (qa-assert-equal 5 (ldb (byte 28 28) node))
    (qa-assert-equal 3 (ldb (byte 4 56) node))))

(deftest test-ast-to-dag-simple
  (let ((dag (flatten-ast-dag '(succ zero))))
    ;; (0: zero node [1 0 0], 1: succ node [3 0 0])
    (qa-assert-equal 2 (length dag))
    (qa-assert-equal 1 (first (nth 0 dag))) ; zero tag
    (qa-assert-equal 3 (first (nth 1 dag))) ; succ tag
    (qa-assert-equal 0 (second (nth 1 dag))))) ; index of zero

(deftest test-get-gn-consistency
  (let ((gn1 (get-gn '(eq (var "x") zero)))
        (gn2 (get-gn '(eq (var "x") zero))))
    (qa-assert-equal gn1 gn2))
  (let ((gn1 (get-gn '(eq "x" 0)))
        (gn2 (get-gn '(eq "y" 0))))
    (qa-assert-true (not (equal gn1 gn2)))))

(deftest test-count-nodes
  (qa-assert-equal 2 (count-nodes-dag '(succ zero)))
  (qa-assert-equal 1 (count-nodes-dag 'zero)))
