;;; wysiwym.el --- WYSIWYM mode for markdown -*- lexical-binding: t; -*-

;;; Commentary:
;; Provides a "What You See Is What You Mean" mode for markdown buffers.
;; Combines markup hiding, table alignment, inline images, centered writing,
;; and mermaid diagram rendering into a single toggle.
;;
;; Keybindings (markdown-mode, localleader):
;;   SPC m w   — toggle full WYSIWYM mode (all features on/off)
;;   SPC m t v — toggle valign-mode (table alignment)
;;   SPC m t o — toggle olivetti-mode (centered writing)
;;   SPC m t r — toggle mermaid rendering (inline overlays via mmdc)

;;; Code:

;; --- Mermaid overlay rendering ---

(defvar-local my/mermaid-overlays nil
  "List of overlays displaying rendered mermaid diagrams.")

(defun my/mermaid-render-all ()
  "Render all mermaid code blocks as inline image overlays using mmdc."
  (interactive)
  (unless (executable-find "mmdc")
    (user-error "mmdc (mermaid-cli) not found in PATH"))
  (my/mermaid-clear-all)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "^```mermaid\n" nil t)
      (let ((block-start (match-beginning 0))
            (content-start (point)))
        (when (re-search-forward "^```$" nil t)
          (let* ((content-end (match-beginning 0))
                 (block-end (match-end 0))
                 (content (buffer-substring-no-properties content-start content-end))
                 (tmp-in (make-temp-file "mermaid-" nil ".mmd"))
                 (tmp-out (make-temp-file "mermaid-" nil ".png")))
            (write-region content nil tmp-in nil 'quiet)
            (let ((err-buf (generate-new-buffer " *mmdc-err*")))
              (let ((win-width (- (window-body-width nil t)
                                   (line-number-display-width t))))
                (if (= 0 (apply #'call-process "mmdc" nil (list err-buf nil) nil
                                        "-i" tmp-in "-o" tmp-out
                                        "-t" "dark" "-b" "transparent"
                                        "-w" (number-to-string (* 2 win-width))
                                        (when (and (boundp 'my/mermaid-puppeteer-config)
                                                   (file-exists-p my/mermaid-puppeteer-config))
                                          (list "-p" my/mermaid-puppeteer-config))))
                    (let ((ov (make-overlay block-start block-end)))
                      (overlay-put ov 'display
                                   (create-image tmp-out 'png nil :width win-width))
                      (overlay-put ov 'my/mermaid t)
                      (overlay-put ov 'evaporate t)
                      (push ov my/mermaid-overlays))
                  (message "mmdc failed at line %d: %s"
                           (line-number-at-pos block-start)
                           (with-current-buffer err-buf (buffer-string)))))
              (kill-buffer err-buf))
            (delete-file tmp-in)))))))


(defun my/mermaid-clear-all ()
  "Remove all mermaid image overlays from the current buffer."
  (interactive)
  (dolist (ov my/mermaid-overlays)
    (when (overlay-buffer ov)
      (delete-overlay ov)))
  (setq my/mermaid-overlays nil))

(defun my/markdown-toggle-mermaid ()
  "Toggle mermaid diagram rendering overlays on/off."
  (interactive)
  (if my/mermaid-overlays
      (my/mermaid-clear-all)
    (my/mermaid-render-all)))

(defun my/mermaid-view-at-point ()
  "Render the mermaid block at point and open in an external image viewer."
  (interactive)
  (unless (executable-find "mmdc")
    (user-error "mmdc (mermaid-cli) not found in PATH"))
  (save-excursion
    (let ((pos (point)))
      ;; Find the enclosing ```mermaid ... ``` block
      (unless (re-search-backward "^```mermaid$" nil t)
        (user-error "No mermaid block at point"))
      (let ((content-start (1+ (line-end-position))))
        (unless (re-search-forward "^```$" nil t)
          (user-error "Unterminated mermaid block"))
        (let ((content-end (match-beginning 0)))
          (unless (and (>= pos (match-beginning 0))
                       ;; point was between the fences (use original block start)
                       t)
            ;; Verify point was actually inside this block
            (when (< pos content-start)
              (user-error "No mermaid block at point")))
          (let* ((content (buffer-substring-no-properties content-start content-end))
                 (tmp-in (make-temp-file "mermaid-" nil ".mmd"))
                 (tmp-out (make-temp-file "mermaid-view-" nil ".png"))
                 (viewer (or (executable-find "feh")
                             (executable-find "eog")
                             (executable-find "xdg-open")
                             (user-error "No image viewer found"))))
            (write-region content nil tmp-in nil 'quiet)
            (if (= 0 (apply #'call-process "mmdc" nil nil nil
                              "-i" tmp-in "-o" tmp-out
                              "-t" "dark" "-b" "transparent"
                              "-w" "1600"
                              (when (and (boundp 'my/mermaid-puppeteer-config)
                                         (file-exists-p my/mermaid-puppeteer-config))
                                (list "-p" my/mermaid-puppeteer-config))))
                (start-process "mermaid-view" nil viewer tmp-out)
              (user-error "mmdc rendering failed"))
            (delete-file tmp-in)))))))

;; --- Word wrap with hanging indent ---

(defun my/markdown-toggle-word-wrap ()
  "Toggle visual-line-mode with adaptive-wrap for hanging bullet indent."
  (interactive)
  (if visual-line-mode
      (progn
        (visual-line-mode -1)
        (adaptive-wrap-prefix-mode -1))
    (visual-line-mode 1)
    (adaptive-wrap-prefix-mode 1)))

;; --- WYSIWYM master toggle ---

(defvar-local my/wysiwym--markup-was-hidden nil
  "Whether markup hiding was already active before WYSIWYM was enabled.")

;;;###autoload
(define-minor-mode my/wysiwym-mode
  "WYSIWYM mode: toggle all visual enhancements for markdown at once.
Enables/disables markup hiding, valign, iimage, and mermaid overlays.
Olivetti is available separately via SPC m t o."
  :lighter " [WYSIWYM]"
  :group 'markdown
  (if my/wysiwym-mode
      ;; Turn everything on
      (progn
        (setq my/wysiwym--markup-was-hidden markdown-hide-markup)
        (unless markdown-hide-markup
          (markdown-toggle-markup-hiding))
        (valign-mode 1)
        (iimage-mode 1)
        (visual-line-mode 1)
        (adaptive-wrap-prefix-mode 1)
        (my/mermaid-render-all))
    ;; Turn everything off
    (unless my/wysiwym--markup-was-hidden
      (when markdown-hide-markup
        (markdown-toggle-markup-hiding)))
    (valign-mode -1)
    (iimage-mode -1)
    (visual-line-mode -1)
    (adaptive-wrap-prefix-mode -1)
    (my/mermaid-clear-all)))

;; --- Pixel scrolling for smooth image navigation ---

(when (fboundp 'pixel-scroll-precision-mode)
  (add-hook 'markdown-mode-hook #'pixel-scroll-precision-mode))

;; --- Keybindings ---

(after! markdown-mode
  (map! :map markdown-mode-map
        :localleader
        :desc "WYSIWYM mode" "w" #'my/wysiwym-mode
        (:prefix ("t" . "toggle")
         :desc "Valign (tables)" "v" #'valign-mode
         :desc "Olivetti (center)" "o" #'olivetti-mode
         :desc "Mermaid render" "r" #'my/markdown-toggle-mermaid
         :desc "Mermaid pop out" "R" #'my/mermaid-view-at-point
         :desc "Word wrap (hanging)" "w" #'my/markdown-toggle-word-wrap)))

(provide 'wysiwym)
;;; wysiwym.el ends here
