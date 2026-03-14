;;; markdown-preview.el --- Mermaid major mode with preview -*- lexical-binding: t; -*-

;; Major mode for .mmd files with render-to-PNG preview.
;; SPC m p — pop out in image viewer (local)
;; SPC m i — inline overlay in buffer (SSH fallback)

;;; Code:

(defvar my/mermaid-puppeteer-config
  (expand-file-name "~/.puppeteerrc.json")
  "Path to puppeteer config for mmdc (needed for sandbox workaround).")

(defvar-local my/mermaid-inline-overlay nil
  "Overlay for inline mermaid preview in the buffer.")

(defun my/mermaid-render-to-png ()
  "Render current buffer as mermaid diagram to a temp PNG. Returns the path."
  (unless (executable-find "mmdc")
    (user-error "mmdc (mermaid-cli) not found in PATH"))
  (let ((tmp-in (make-temp-file "mermaid-" nil ".mmd"))
        (tmp-out (make-temp-file "mermaid-" nil ".png")))
    (write-region (point-min) (point-max) tmp-in nil 'quiet)
    (if (= 0 (apply #'call-process "mmdc" nil nil nil
                            "-i" tmp-in "-o" tmp-out
                            "-t" "dark" "-b" "transparent"
                            "-w" "1200"
                            (when (file-exists-p my/mermaid-puppeteer-config)
                              (list "-p" my/mermaid-puppeteer-config))))
        (progn (delete-file tmp-in) tmp-out)
      (delete-file tmp-in)
      (delete-file tmp-out)
      (user-error "mmdc rendering failed"))))

(defun my/mermaid-view ()
  "Render mermaid diagram and open in external image viewer."
  (interactive)
  (let ((png (my/mermaid-render-to-png)))
    (start-process "mermaid-view" nil
                   (or (executable-find "feh")
                       (executable-find "eog")
                       (executable-find "xdg-open")
                       (user-error "No image viewer found (feh, eog, xdg-open)"))
                   png)))

(defun my/mermaid-view-inline ()
  "Render mermaid diagram as inline overlay at end of buffer."
  (interactive)
  (my/mermaid-clear-inline)
  (let ((png (my/mermaid-render-to-png)))
    (save-excursion
      (goto-char (point-max))
      (let ((ov (make-overlay (point-max) (point-max))))
        (overlay-put ov 'after-string
                     (propertize "\n"
                                 'display (create-image png 'png nil :max-width 800)))
        (overlay-put ov 'my/mermaid-inline t)
        (setq my/mermaid-inline-overlay ov)))))

(defun my/mermaid-clear-inline ()
  "Remove inline mermaid preview overlay."
  (interactive)
  (when (and my/mermaid-inline-overlay
             (overlay-buffer my/mermaid-inline-overlay))
    (delete-overlay my/mermaid-inline-overlay))
  (setq my/mermaid-inline-overlay nil))

;; Major mode
(define-derived-mode mermaid-mode fundamental-mode "Mermaid"
  "Major mode for editing Mermaid diagram files (.mmd).")

(add-to-list 'auto-mode-alist '("\\.mmd\\'" . mermaid-mode))

;; Keybindings
(map! :map mermaid-mode-map
      :localleader
      :desc "Preview (external)" "p" #'my/mermaid-view
      :desc "Preview (inline)"   "i" #'my/mermaid-view-inline
      :desc "Clear inline"       "c" #'my/mermaid-clear-inline)

(provide 'markdown-preview)
;;; markdown-preview.el ends here
