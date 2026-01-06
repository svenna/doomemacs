;;; claude.el --- Claude AI integration -*- lexical-binding: t; -*-

;; Claude AI Emacs integration for AI-assisted development

;;; Commentary:
;; This module integrates Claude AI with Emacs through:
;; - claude-code.el: Terminal-based Claude sessions (CLI)
;; - monet: IDE protocol for selections, diagnostics, and diffs
;; - efrit: Native Emacs Claude agent (API-based)
;;
;; Keybindings under SPC k (Kustom apps namespace):
;; - SPC k c: Claude CLI (transient menu)
;; - SPC k e: Efrit (native agent)

;;; Code:

(use-package! inheritenv
  :demand t)

(use-package! eat
  :demand t)

(use-package! claude-code
  :after (inheritenv eat)
  :config
  ;; Use eat as terminal backend
  (setq claude-code-terminal 'eat)

  ;; Enable claude-code mode globally
  (claude-code-mode 1))

(use-package! monet
  :config
  ;; Enable monet mode for IDE protocol
  (monet-mode 1))

;; Set efrit directory BEFORE package loads (efrit auto-initializes on load)
(setq efrit-data-directory (expand-file-name ".efrit" doom-local-dir))

(use-package! efrit
  :commands (efrit-chat efrit-do efrit-agent efrit-doctor)
  :config
  ;; API key from environment variable ANTHROPIC_API_KEY

  ;; Evil keybindings for efrit-mode
  (map! :map efrit-mode-map
        :n "RET" #'efrit-send-buffer-message
        :i "S-<return>" #'efrit-insert-newline
        :i "C-<return>" #'efrit-send-buffer-message
        :n "q" #'quit-window)

  ;; Set efrit buffers to insert state by default
  (add-hook 'efrit-mode-hook #'evil-insert-state))

;; Keybindings: SPC k for Kustom apps
(map! :leader
      :desc "Kustom apps" "k" nil  ; Clear any existing binding
      (:prefix ("k" . "kustom")
       :desc "Claude CLI" "c" #'claude-code-transient
       (:prefix ("e" . "efrit")
        :desc "Chat" "c" #'efrit-chat
        :desc "Do" "d" #'efrit-do
        :desc "Agent" "a" #'efrit-agent
        :desc "Doctor" "?" #'efrit-doctor)
       (:prefix ("m" . "monet")
        :desc "Start server" "s" #'monet-start-server
        :desc "Stop server" "k" #'monet-stop-server
        :desc "List sessions" "l" #'monet-list-sessions)))

(provide 'claude)
;;; claude.el ends here
