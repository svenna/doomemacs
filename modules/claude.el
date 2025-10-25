;;; claude.el --- Claude Code and Monet integration -*- lexical-binding: t; -*-

;; Claude Code Emacs integration for AI-assisted development
;; Monet implements Claude Code IDE protocol via WebSocket

;;; Commentary:
;; This module integrates Claude Code CLI with Emacs through:
;; - claude-code.el: Terminal-based Claude sessions
;; - monet: IDE protocol for selections, diagnostics, and diffs
;;
;; Keybindings under SPC k (Kustom apps namespace):
;; - SPC k c: Claude command map (transient menu)

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

;; Keybindings: SPC k for Kustom apps, SPC k c for Claude, SPC k m for Monet
(map! :leader
      :desc "Kustom apps" "k" nil  ; Clear any existing binding
      (:prefix ("k" . "kustom")
       :desc "Claude" "c" #'claude-code-transient
       (:prefix ("m" . "monet")
        :desc "Start server" "s" #'monet-start-server
        :desc "Stop server" "k" #'monet-stop-server
        :desc "Restart server" "r" #'monet-restart-server
        :desc "Server status" "?" #'monet-status)))

(provide 'claude)
;;; claude.el ends here
