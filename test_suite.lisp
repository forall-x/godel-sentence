;;;; test_suite.lisp - Master test runner

(unless (fboundp 'test-helper-loaded) (load "test_helper.lisp"))
(load "test_core.lisp")
(load "test_syntax.lisp")
(load "test_sequence.lisp")
(load "test_numeric.lisp")
(load "test_predicates.lisp")
(load "test_robustness.lisp")

(run-all-tests)
