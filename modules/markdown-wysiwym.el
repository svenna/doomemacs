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
            (if (= 0 (call-process "mmdc" nil nil nil
                                    "-i" tmp-in "-o" tmp-out
                                    "-t" "dark" "-b" "transparent"
                                    "-w" "800"))
                (let ((ov (make-overlay block-start block-end)))
                  (overlay-put ov 'display
                               (create-image tmp-out 'png nil :max-width 700))
                  (overlay-put ov 'my/mermaid t)
                  (overlay-put ov 'evaporate t)
                  (push ov my/mermaid-overlays))
              (message "mmdc failed for mermaid block at line %d"
                       (line-number-at-pos block-start)))
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

;; --- WYSIWYM master toggle ---

(defvar-local my/wysiwym--markup-was-hidden nil
  "Whether markup hiding was already active before WYSIWYM was enabled.")

;;;###autoload
(define-minor-mode my/wysiwym-mode
  "WYSIWYM mode: toggle all visual enhancements for markdown at once.
Enables/disables markup hiding, valign, iimage, olivetti, and mermaid overlays."
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
        (olivetti-mode 1)
        (my/mermaid-render-all))
    ;; Turn everything off
    (unless my/wysiwym--markup-was-hidden
      (when markdown-hide-markup
        (markdown-toggle-markup-hiding)))
    (valign-mode -1)
    (iimage-mode -1)
    (olivetti-mode -1)
    (my/mermaid-clear-all)))

;; --- Package configuration ---

(use-package! valign
  :commands valign-mode
  :config
  (setq valign-fancy-bar t))

(use-package! olivetti
  :commands olivetti-mode
  :config
  (setq olivetti-body-width 80))

;; --- Keybindings ---

(after! markdown-mode
  (map! :map markdown-mode-map
        :localleader
        :desc "WYSIWYM mode" "w" #'my/wysiwym-mode
        (:prefix ("t" . "toggle")
         :desc "Valign (tables)" "v" #'valign-mode
         :desc "Olivetti (center)" "o" #'olivetti-mode
         :desc "Mermaid render" "r" #'my/markdown-toggle-mermaid)))

(provide 'wysiwym)
;;; wysiwym.el ends here
