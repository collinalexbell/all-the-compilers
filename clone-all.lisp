(defpackage :compilers (:use :cl))
(in-package :compilers)

(defun get-urls ()
  (let ((f (open "awesome-compilers/urls")))
    (loop for line = (read-line f nil)
          while line collect (format nil "~a" line))))

(defun sh (cmd args)
  (sb-ext:run-program cmd
                      args 
                      :input nil
                      :output *standard-output*))

(defun shell (cmd subcmd args)
  (if (equalp cmd "git")
      (sb-ext:run-program "/usr/bin/git"
                          (list subcmd args)
                          :input nil
                          :output *standard-output*)
      ))

(defun clone-all ()
  (loop for url in (get-urls) do (shell "git" "clone" url)))

(defun ls (&optional (loc "./"))
  (sb-ext:run-program "/usr/bin/ls"
                      (list loc)
                      :input nil
                      :output *standard-output*))
