;;; markdown-preview.el --- Mermaid mode and preview -*- lexical-binding: t; -*-

;; Simple major mode for .mmd files with Chrome-based preview

;;; Code:

(defun my/mermaid-preview ()
  "Preview standalone Mermaid diagram (.mmd) in Chrome with dark theme."
  (interactive)
  (let ((output-file "/tmp/mermaid-preview.html")
        (mermaid-content (buffer-string))
        (css-content (with-temp-buffer
                       (insert-file-contents (expand-file-name "modules/markdown-preview-dark.css" doom-user-dir))
                       (buffer-string))))
    (with-temp-file output-file
      (insert (format "<!DOCTYPE html>
<html>
<head>
  <meta charset=\"utf-8\">
  <title>Mermaid Preview</title>
  <style>
%s
  </style>
</head>
<body>
  <script type=\"module\">
    import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs';
    mermaid.initialize({
      startOnLoad: true,
      theme: 'dark',
      themeVariables: {
        darkMode: true,
        background: '#1e1e1e',
        primaryColor: '#58a6ff',
        primaryTextColor: '#ffffff',
        primaryBorderColor: '#58a6ff',
        lineColor: '#58a6ff',
        secondaryColor: '#7ee787',
        tertiaryColor: '#f778ba',
        textColor: '#ffffff',
        labelTextColor: '#ffffff',
        edgeLabelBackground: '#0d1117',
        mainBkg: '#0d1117',
        secondBkg: '#161b22',
        border1: '#30363d',
        border2: '#58a6ff',
        note: '#ffa657',
        noteBkgColor: '#4a2600',
        noteTextColor: '#ffffff',
        noteBorderColor: '#ffa657',
        c4ShapeInRow: 4,
        c4BoundaryInRow: 2,
        personFill: '#58a6ff',
        personBorder: '#79c0ff',
        systemFill: '#7ee787',
        systemBorder: '#9be9a8',
        systemDbFill: '#f778ba',
        systemDbBorder: '#ffb3d9',
        externalPersonFill: '#6e7681',
        externalPersonBorder: '#8b949e',
        externalSystemFill: '#6e7681',
        externalSystemBorder: '#8b949e',
        componentFill: '#0d1117',
        componentBorder: '#58a6ff',
        componentTextColor: '#ffffff',
        containerFill: '#161b22',
        containerBorder: '#7ee787',
        containerTextColor: '#ffffff'
      }
    });
    window.addEventListener('load', () => {
      setTimeout(() => {
        document.querySelectorAll('.mermaid').forEach(el => {
          if (el.getAttribute('data-processed') === 'true') {
            el.querySelectorAll('.edgeLabel span, .edgeLabel foreignObject div, text.edgeLabel').forEach(label => {
              label.style.color = '#ffffff';
              label.style.fill = '#ffffff';
            });
            el.querySelectorAll('.edgeLabel rect').forEach(rect => {
              rect.style.fill = '#0d1117';
            });
            el.querySelectorAll('rect[class*=\"component\"], rect[class*=\"container\"]').forEach(box => {
              if (!box.classList.contains('edgeLabel')) {
                box.style.fill = '#0d1117';
                box.style.stroke = '#58a6ff';
              }
            });
            el.querySelectorAll('g[class*=\"component\"] text, g[class*=\"container\"] text').forEach(text => {
              text.style.fill = '#ffffff';
            });
          }
        });
      }, 500);
    });
  </script>
  <div class=\"mermaid\">
%s
  </div>
</body>
</html>"
                      css-content
                      mermaid-content)))
    (unless (get-buffer-process "*mermaid-preview*")
      (start-process "mermaid-preview" "*mermaid-preview*"
                     (or (executable-find "google-chrome")
                         (executable-find "google-chrome-stable"))
                     output-file))))

;; Simple major mode for .mmd files
(define-derived-mode mermaid-mode fundamental-mode "Mermaid"
  "Major mode for editing Mermaid diagram files (.mmd).")

(add-to-list 'auto-mode-alist '("\\.mmd\\'" . mermaid-mode))

;; Keybinding: SPC m p in mermaid mode
(map! :map mermaid-mode-map
      :localleader
      "p" #'my/mermaid-preview)

(provide 'markdown-preview)
;;; markdown-preview.el ends here
