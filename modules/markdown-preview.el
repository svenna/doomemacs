;;; markdown-preview.el --- Mermaid major mode -*- lexical-binding: t; -*-

;; Simple major mode for .mmd files

;;; Code:

(define-derived-mode mermaid-mode fundamental-mode "Mermaid"
  "Major mode for editing Mermaid diagram files (.mmd).")

(add-to-list 'auto-mode-alist '("\\.mmd\\'" . mermaid-mode))

(provide 'markdown-preview)
;;; markdown-preview.el ends here
