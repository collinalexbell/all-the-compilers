#-quicklisp
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                       (user-homedir-pathname))))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))

(ql:quickload :uiop :silent t)
(ql:quickload :cl-ppcre :silent t)
(ql:quickload :genhash :silent t)
(ql:quickload :alexandria :silent t)

#-mkcl (ql:quickload :cl-readline :silent t)
#+mkcl (load "fake-readline.lisp")

(defpackage #:mal-asd
  (:use :cl :asdf))

(in-package :mal-asd)

(defsystem "step3_env"
  :name "MAL"
  :version "1.0"
  :author "Iqbal Ansari"
  :description "Implementation of step 3 of MAL in Common Lisp"
  :serial t
  :components ((:file "utils")
               (:file "types")
               (:file "env")
               (:file "reader")
               (:file "printer")
               (:file "step3_env"))
  :depends-on (:uiop :cl-readline :cl-ppcre :genhash)
  :pathname "src/")
