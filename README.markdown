# Rove

Rove is a unit testing framework for Common Lisp applications. This is intended to be the next major release of [Prove](https://github.com/fukamachi/prove).

## Warning

This software is still ALPHA quality. The APIs will be likely to change.

## Differences from Prove

* Supports ASDF's package-inferred-system
* Fewer dependencies (Only depends on Trivial-Gray-Streams and UIOP)
* Report details of failure tests
* Thread-support

## Usage

```common-lisp
(defpackage jsonrpc/tests/request
  (:use :cl
        :rove
        :jsonrpc/request))
(in-package :jsonrpc/tests/request)

(deftest parse-message-test
  (testing "invalid message"
    (ok (signals (parse-message "xxx") 'jsonrpc-parse-error)
        "Parse error")))
```

```
$ rove tests/request.lisp
```

## API Reference

### ok (form &optional description)

```common-lisp
(ok (= a 10))
;-> ✓ Expect (= A 10) to be true.

(ok (= a 0))
;-> × 0) Expect (= A 0) to be true.
```

### ng (form &optional description)

```common-lisp
(ng (= a 10))
;-> × 0) Expect (= A 10) to be false.

(ng (= a 0))
;-> ✓ Expect (= A 0) to be false.
```

### signals (form &optional condition)

```common-lisp
(ok (signals (raise-error-form)))
```

### outputs (form content &optional stream)

```common-lisp
(ok (outputs (write-string "a") "a"))
;-> ✓ Expect (OUTPUTS (WRITE-STRING a) a) to be true.
```

### expands (form expanded-form &optional env)

```common-lisp
(defmacro defun-addn (n)
  (let ((m (gensym "m")))
    `(defun ,(intern (format nil "ADD~A" n)) (,m)
       (+ ,m ,n))))

(ok (expands '(defun-addn 10)
             `(defun add10 (#:m)
                (+ #:m 10))))
```

### pass (description)

```common-lisp
(pass "Okay. It's passed")
;-> ✓ Okay. It's passed
```

### fail (description)

```common-lisp
(fail "Oops. It's failed")
;-> × Oops. It's failed
```

### skip (description)

```common-lisp
(skip "Skipped for now.")
;-> - Skipped for now.
```

### deftest (name &body body)

```common-lisp
(deftest testing-length
  (ok (= (length #(1 2 3)) 3)))
```

### testing (description &body body)

```common-lisp
(deftest testing-length
  (testing "array"
    (ok (= (length #(1 2 3)) 3)))

  (testing "list"
    (ok (= (length (list 1 2 3)) 3))))
```

### setup (&body body)

Evaluates before testing the package once. This would be useful for initialization of tests, like establishment to the DB or creating a temporary directory.

Use `(defhook :before ...)` instead for running before each test.

```common-lisp
(setup
  (ensure-directories-exist *tmp-directory*))
```

### teardown (&body body)

Evaluates after testing the package once. This is executed even when the test is interrupted with some reason. This would be useful for cleanup of tests, like disconnecting from DB or deleting a temporary directory.

Use `(defhook :after ...)` instead for running after each test.

```common-lisp
(teardown
  (uiop:delete-directory-tree *tmp-directory* validate t :if-does-not-exist :ignore))
```

### defhook (mode &body body)

Evaluates before/after running a each test in the package.

### run (package &key style env)

```common-lisp
(run :myapp/tests)
(run :myapp/tests :style :spec)
(run :myapp/tests :env '(("APP_ENV" . "test")))
```

## Examples

* [fukamachi/jsonrpc](https://github.com/fukamachi/jsonrpc)

## Author

* Eitaro Fukamachi (e.arrows@gmail.com)

## Copyright

Copyright (c) 2017 Eitaro Fukamachi

## License

Licensed under the BSD 3-Clause License.
