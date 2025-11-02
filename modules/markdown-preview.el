;;; markdown-preview.el --- Markdown preview with Mermaid support -*- lexical-binding: t; -*-

;; Simple markdown preview with Mermaid diagram support and dark theme
;; Uses Pandoc for conversion and Chrome for rendering

(defun my/markdown-preview ()
  "Preview markdown with Mermaid in Chrome using dark theme"
  (interactive)
  (let ((output-file "/tmp/markdown-preview.html")
        (css-file (expand-file-name "modules/markdown-preview-dark.css" doom-user-dir)))
    ;; Step 1: Convert markdown to HTML with dark CSS
    ;; Use GFM (GitHub Flavored Markdown) which handles lists without blank lines
    (shell-command
     (format "pandoc -s -f gfm -t html --metadata title=\"Preview\" --css=%s %s -o %s"
             (shell-quote-argument css-file)
             (shell-quote-argument (buffer-file-name))
             output-file))

    ;; Step 2: Add Mermaid.js support via script injection
    (shell-command
     (format "sed -i 's/<body>/<body><script type=\"module\">import mermaid from \"https:\\/\\/cdn.jsdelivr.net\\/npm\\/mermaid@10\\/dist\\/mermaid.esm.min.mjs\";mermaid.initialize({startOnLoad:true,theme:\"dark\"});window.addEventListener(\"load\",()=>{setTimeout(()=>{document.querySelectorAll(\".mermaid\").forEach(el=>{if(el.getAttribute(\"data-processed\")===\"true\"\\&\\&el.innerHTML.includes(\"Syntax error\")){el.classList.add(\"mermaid-error\");el.innerHTML=\"⚠️ MERMAID SYNTAX ERROR ⚠️<br><br>\"+el.textContent;}})},500)});<\\/script>/' %s"
             output-file))

    ;; Step 3: Transform Mermaid code blocks to divs for rendering
    (shell-command
     (format "sed -i 's/<pre class=\"mermaid\"><code>/<div class=\"mermaid\">/g' %s" output-file))
    (shell-command
     (format "sed -i '/<div class=\"mermaid\">/,/<\\/code><\\/pre>/ s/<\\/code><\\/pre>/<\\/div>/' %s" output-file))

    ;; Step 4: Open in Chrome
    (unless (get-buffer-process "*markdown-preview*")
      (start-process "markdown-preview" "*markdown-preview*"
                     (or (executable-find "google-chrome")
                         (executable-find "google-chrome-stable"))
                     output-file))))

(defun my/mermaid-preview ()
  "Preview standalone Mermaid diagram (.mmd) in Chrome with dark theme"
  (interactive)
  (let ((output-file "/tmp/mermaid-preview.html")
        (css-file (expand-file-name "modules/markdown-preview-dark.css" doom-user-dir))
        (mermaid-content (buffer-string)))
    (with-temp-file output-file
      (insert (format "<!DOCTYPE html>
<html>
<head>
  <meta charset=\"utf-8\">
  <title>Mermaid Preview</title>
  <link rel=\"stylesheet\" href=\"%s\">
</head>
<body>
  <script type=\"module\">
    import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs';
    mermaid.initialize({ startOnLoad: true, theme: 'dark' });
    window.addEventListener('load', () => {
      setTimeout(() => {
        document.querySelectorAll('.mermaid').forEach(el => {
          if (el.getAttribute('data-processed') === 'true' && el.innerHTML.includes('Syntax error')) {
            el.classList.add('mermaid-error');
            el.innerHTML = '⚠️ MERMAID SYNTAX ERROR ⚠️<br><br>' + el.textContent;
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
                      css-file
                      mermaid-content)))
    (unless (get-buffer-process "*mermaid-preview*")
      (start-process "mermaid-preview" "*mermaid-preview*"
                     (or (executable-find "google-chrome")
                         (executable-find "google-chrome-stable"))
                     output-file))))

;; Simple major mode for .mmd files
(define-derived-mode mermaid-mode fundamental-mode "Mermaid"
  "Major mode for editing Mermaid diagram files (.mmd).")

;; Associate .mmd files with mermaid-mode
(add-to-list 'auto-mode-alist '("\\.mmd\\'" . mermaid-mode))

;; Keybinding: SPC m p in markdown mode
(map! :map markdown-mode-map
      :localleader
      "p" #'my/markdown-preview)

;; Keybinding: SPC m p in mermaid mode
(map! :map mermaid-mode-map
      :localleader
      "p" #'my/mermaid-preview)

(provide 'markdown-preview)
;;; markdown-preview.el ends here
