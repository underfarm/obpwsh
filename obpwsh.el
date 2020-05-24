
(defun clear-term-buffer ()
  (interactive)
  (setf (buffer-string) ""))


(defun ob-pwsh-initiate-term ()
  (unless (get-buffer-process (get-buffer "*terminal*"))
    (term "/usr/bin/pwsh")))

(defun org-babel-expand-body:pwsh (body params)
  "Expands the body of a Pwsh code block."
  ;; Currently we don't do any expansion for tangled blocks. Just return
  ;; body unmodified as specified by the user.
  body)

(defun org-babel-execute:pwsh (body params)
  "Executes a Powershell code block."
  ;; Round up the stuff we need
  (let* ((expanded-body (org-babel-expand-body:pwsh body params)))
    (ob-pwsh-initiate-term)
    (exec-pwsh-with-term expanded-body)))

(defun exec-pwsh-with-term (toSend)
  (with-current-buffer "*terminal*"
    (clear-term-buffer)
    (let* ((powershell-prompt-regex "PS [^#$%>]+>.+#!#")
           (prevpoint (point))
           (sendString toSend)
           (proc (get-buffer-process (get-buffer "*terminal*"))))
      (term-send-string proc (concat sendString "\n #!#"))

      ;; Wait until the prompt have returned with #!# at the end.
      ;;
      (while
          (unless (re-search-backward powershell-prompt-regex nil t)
            (sit-for 2)))

      (setq termoutput (buffer-substring-no-properties prevpoint (point) ))
      (clear-term-buffer) ;; This is needed because..wtf? race-condition?
      (term-send-string proc " \n"))
    termoutput))


(provide 'obpwsh)
