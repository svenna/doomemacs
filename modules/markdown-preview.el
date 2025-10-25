;;; markdown-preview.el --- Markdown preview with Mermaid support -*- lexical-binding: t; -*-

;; Simple markdown preview with Mermaid diagram support and dark theme
;; Uses Pandoc for conversion and Chrome for rendering

(defun my/markdown-preview ()
  "Preview markdown with Mermaid in Chrome"
  (interactive)
  (let ((output-file "/tmp/markdown-preview.html"))
    (shell-command
     (format "pandoc -s -f markdown -t html --metadata title=\"Preview\" %s -o %s && sed -i '/<\\/head>/i <style>*,*::before,*::after{box-sizing:border-box}body{max-width:800px;margin:0 auto;padding:40px;font-size:16px;background:#1e1e1e;color:#d4d4d4;font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Helvetica,Arial,sans-serif;line-height:1.6}p,li,td,th,div:not(.mermaid){font-size:16px}h1,h2,h3,h4,h5,h6{color:#ffffff;font-weight:600;margin-top:24px;margin-bottom:16px;line-height:1.25}h1{font-size:32px;border-bottom:1px solid #404040;padding-bottom:0.3em}h2{font-size:24px;border-bottom:1px solid #404040;padding-bottom:0.3em}h3{font-size:20px}h4,h5,h6{font-size:16px}code,pre,pre *{font-size:14px}code{background:#0d1117;padding:0.2em 0.4em;border-radius:3px;font-family:SFMono-Regular,Consolas,Liberation Mono,Menlo,monospace;color:#7ee787}pre{background:#0d1117;padding:16px;border-radius:6px;overflow:auto;line-height:1.45;border:1px solid #30363d;color:#e6edf3}pre code{background:transparent;padding:0;color:#e6edf3}a{color:#58a6ff;text-decoration:none}a:hover{text-decoration:underline}table{border-collapse:collapse;margin:16px 0}table th,table td{border:1px solid #30363d;padding:6px 13px;font-size:16px}table th{background:#161b22;font-weight:600;color:#ffffff}table tr:nth-child(2n){background:#0d1117}strong{color:#ffffff;font-size:inherit}</style>' %s && sed -i 's/<body>/<body><script type=\"module\">import mermaid from \"https:\\/\\/cdn.jsdelivr.net\\/npm\\/mermaid@10\\/dist\\/mermaid.esm.min.mjs\";mermaid.initialize({startOnLoad:true,theme:\"dark\"});<\\/script>/' %s && sed -i 's/<pre class=\"mermaid\"><code>/<div class=\"mermaid\">/g' %s && sed -i '/<div class=\"mermaid\">/,/<\\/code><\\/pre>/ s/<\\/code><\\/pre>/<\\/div>/' %s"
             (shell-quote-argument (buffer-file-name))
             output-file
             output-file
             output-file
             output-file
             output-file))
    (unless (get-buffer-process "*markdown-preview*")
      (start-process "markdown-preview" "*markdown-preview*"
                     (or (executable-find "google-chrome")
                         (executable-find "google-chrome-stable"))
                     output-file))))

;; Keybinding: SPC m p in markdown mode
(map! :map markdown-mode-map
      :localleader
      "p" #'my/markdown-preview)

(provide 'markdown-preview)
;;; markdown-preview.el ends here
