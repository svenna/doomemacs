;;; markdown-preview.el --- Markdown preview with Mermaid support -*- lexical-binding: t; -*-

;; Simple markdown preview with Mermaid diagram support and dark theme
;; Uses Pandoc for conversion and Chrome for rendering

(defun my/markdown-preview ()
  "Preview markdown with Mermaid in Chrome using dark theme"
  (interactive)
  (let ((output-file "/tmp/markdown-preview.html")
        (css-file (expand-file-name "modules/markdown-preview-dark.css" doom-user-dir)))
    ;; Step 1: Convert markdown to HTML
    ;; Use GFM (GitHub Flavored Markdown) which handles lists without blank lines
    (shell-command
     (format "pandoc -s -f gfm -t html --metadata title=\"Preview\" %s -o %s"
             (shell-quote-argument (buffer-file-name))
             output-file))

    ;; Step 1.5: Inline the CSS directly into the HTML (browsers may block external file:// CSS)
    (let ((html-content (with-temp-buffer
                          (insert-file-contents output-file)
                          (buffer-string)))
          (css-content (with-temp-buffer
                         (insert-file-contents css-file)
                         (buffer-string))))
      (with-temp-file output-file
        (insert (replace-regexp-in-string
                 "</head>"
                 (concat "<style>\n" css-content "\n</style>\n</head>")
                 html-content))))

    ;; Step 2: Add Mermaid.js support via script injection with custom C4 colors
    (shell-command
     (format "sed -i 's/<body>/<body><script type=\"module\">import mermaid from \"https:\\/\\/cdn.jsdelivr.net\\/npm\\/mermaid@10\\/dist\\/mermaid.esm.min.mjs\";mermaid.initialize({startOnLoad:true,theme:\"dark\",themeVariables:{darkMode:true,background:\"#1e1e1e\",primaryColor:\"#58a6ff\",primaryTextColor:\"#ffffff\",primaryBorderColor:\"#58a6ff\",lineColor:\"#58a6ff\",secondaryColor:\"#7ee787\",tertiaryColor:\"#f778ba\",textColor:\"#ffffff\",labelTextColor:\"#ffffff\",edgeLabelBackground:\"#0d1117\",mainBkg:\"#0d1117\",secondBkg:\"#161b22\",border1:\"#30363d\",border2:\"#58a6ff\",note:\"#ffa657\",noteBkgColor:\"#4a2600\",noteTextColor:\"#ffffff\",noteBorderColor:\"#ffa657\",c4ShapeInRow:4,c4BoundaryInRow:2,personFill:\"#58a6ff\",personBorder:\"#79c0ff\",systemFill:\"#7ee787\",systemBorder:\"#9be9a8\",systemDbFill:\"#f778ba\",systemDbBorder:\"#ffb3d9\",externalPersonFill:\"#6e7681\",externalPersonBorder:\"#8b949e\",externalSystemFill:\"#6e7681\",externalSystemBorder:\"#8b949e\"}});window.addEventListener(\"load\",()=>{setTimeout(()=>{document.querySelectorAll(\".mermaid\").forEach(el=>{if(el.getAttribute(\"data-processed\")===\"true\"){if(el.innerHTML.includes(\"Syntax error\")){el.classList.add(\"mermaid-error\");el.innerHTML=\"⚠️ MERMAID SYNTAX ERROR ⚠️<br><br>\"+el.textContent;}else{el.querySelectorAll(\".edgeLabel span, .edgeLabel foreignObject div, text.edgeLabel\").forEach(label=>{label.style.color=\"#ffffff\";label.style.fill=\"#ffffff\";});el.querySelectorAll(\".edgeLabel rect\").forEach(rect=>{rect.style.fill=\"#0d1117\";});}}})},500)});<\\/script>/' %s"
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
        externalSystemBorder: '#8b949e'
      }
    });
    window.addEventListener('load', () => {
      setTimeout(() => {
        document.querySelectorAll('.mermaid').forEach(el => {
          if (el.getAttribute('data-processed') === 'true') {
            if (el.innerHTML.includes('Syntax error')) {
              el.classList.add('mermaid-error');
              el.innerHTML = '⚠️ MERMAID SYNTAX ERROR ⚠️<br><br>' + el.textContent;
            } else {
              // Force edge labels to be white
              el.querySelectorAll('.edgeLabel span, .edgeLabel foreignObject div, text.edgeLabel').forEach(label => {
                label.style.color = '#ffffff';
                label.style.fill = '#ffffff';
              });
              el.querySelectorAll('.edgeLabel rect').forEach(rect => {
                rect.style.fill = '#0d1117';
              });
            }
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
