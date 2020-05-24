
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
    ;; Build script in temporary file
    (exec-pwsh-with-term expanded-body)))

(defun exec-pwsh-with-term (toSend)
  (with-current-buffer "*terminal*"
    (let* ((powershell-prompt-regex "PS [^#$%>]+>.+#!#")
           (prevpoint (point))
           (sendString (concat toSend " #!#"))
           (proc (get-buffer-process (get-buffer "*terminal*"))))
      (term-send-string proc sendString)
      (sleep-for 0 5) ;; This is needed because..wtf? race-condition?

      ;; Wait until the prompt have returned with #!# at the end.
      (if (eq nil (re-search-forward powershell-prompt-regex nil t))
          (sleep-for 1))

      ;; I dont want to have our 'end of code' displayed, eg '#!#'.
      (goto-char (point-max))
      (previous-line)
      (goto-char (point-at-eol))

      (setq termoutput (buffer-substring-no-properties prevpoint (point) ))
      (term-send-string proc " \n"))
    (clear-term-buffer) ;; This is needed because..wtf? race-condition?
    termoutput))


(provide 'obpwsh)
