;;; btscript-mode.el --- Major mode for BtScript files -*- lexical-binding: t; -*-

;; Copyright (C) 2024 BeaconTower
;; Author: BeaconTower
;; Version: 0.1.0
;; Package-Requires: ((emacs "26.1"))
;; Keywords: languages, lisp
;; URL: https://github.com/beacontower/btscript

;;; Commentary:

;; Major mode for editing BtScript files (.bts).
;; BtScript is a Lisp-1 dialect for reactive dataflow definitions.

;;; Code:

(require 'lisp-mode)

(defgroup btscript nil
  "Major mode for editing BtScript files."
  :group 'languages
  :prefix "btscript-")

(defcustom btscript-indent-offset 2
  "Basic indentation offset for BtScript."
  :type 'integer
  :group 'btscript)

;; Syntax table (inherit from lisp)
(defvar btscript-mode-syntax-table
  (let ((table (make-syntax-table lisp-mode-syntax-table)))
    ;; ; is comment starter
    (modify-syntax-entry ?\; "<" table)
    ;; newline ends comment
    (modify-syntax-entry ?\n ">" table)
    ;; : is symbol constituent (for keywords)
    (modify-syntax-entry ?: "_" table)
    ;; - is symbol constituent
    (modify-syntax-entry ?- "_" table)
    ;; ? is symbol constituent (for predicates)
    (modify-syntax-entry ?? "_" table)
    ;; ! is symbol constituent (for mutators)
    (modify-syntax-entry ?! "_" table)
    ;; * is symbol constituent (for special vars)
    (modify-syntax-entry ?* "_" table)
    table)
  "Syntax table for `btscript-mode'.")

;; Font-lock keywords
(defconst btscript-special-forms
  '("flow" "inputs" "require" "trigger" "gate"
    "cond" "when" "else"
    "let" "define" "lambda" "def" "defmacro"
    "parallel" "branch" "join"
    "route"
    "emit" "send-command"
    "if" "do" "begin")
  "BtScript special forms.")

(defconst btscript-builtin-functions
  '("rolling-avg" "rolling-min" "rolling-max" "rolling-sum"
    "time-window" "latest" "threshold"
    "avg" "sum" "max" "min" "sqrt"
    "and" "or" "not"
    "null?" "list?" "symbol?" "number?" "string?" "keyword?"
    "car" "cdr" "cons" "nth" "map" "filter"
    "print" "string-append" "join")
  "BtScript built-in functions.")

(defconst btscript-mode-keywords
  '(":id" ":as" ":window" ":input" ":value" ":limit"
    ":on-any" ":zip" ":combine-latest" ":on-timer" ":timer" ":on-change"
    ":interval" ":min" ":max" ":temp" ":pressure" ":rated-power")
  "BtScript keywords (named parameters).")

(defconst btscript-constants
  '("true" "false" "#t" "#f" "else")
  "BtScript constants.")

(defconst btscript-font-lock-keywords
  `(
    ;; Comments (handled by syntax table, but ensure highlighting)
    (";.*$" . font-lock-comment-face)

    ;; Keywords (:keyword)
    (":[a-zA-Z][a-zA-Z0-9-]*" . font-lock-builtin-face)

    ;; Special forms
    (,(concat "(" (regexp-opt btscript-special-forms 'symbols))
     (1 font-lock-keyword-face))

    ;; Built-in functions
    (,(concat "(" (regexp-opt btscript-builtin-functions 'symbols))
     (1 font-lock-function-name-face))

    ;; Constants
    (,(regexp-opt btscript-constants 'symbols) . font-lock-constant-face)

    ;; Duration literals (PT5M, PT1H, etc.)
    ("\\bPT[0-9]+[HMS]\\(?:[0-9]+[HMS]\\)*\\b" . font-lock-constant-face)

    ;; BTI references (btfb:name;version)
    ("\\b[a-zA-Z][a-zA-Z0-9-]*:[a-zA-Z][a-zA-Z0-9-]*;[0-9]+\\.[0-9]+\\.[0-9]+"
     . font-lock-type-face)

    ;; Signal paths in strings ("asset.component.signal")
    ("\"[a-zA-Z_][a-zA-Z0-9_]*\\(?:\\.[a-zA-Z_][a-zA-Z0-9_]*\\)+\""
     . font-lock-string-face)

    ;; Definition names: (define (name ...) or (def name ...)
    ("(def\\(?:ine\\|macro\\)?\\s-+(\\([a-zA-Z][a-zA-Z0-9-?!*]*\\)"
     (1 font-lock-function-name-face))
    ("(def\\s-+\\([a-zA-Z][a-zA-Z0-9-?!*]*\\)"
     (1 font-lock-variable-name-face))

    ;; Flow id
    ("(flow\\s-+:id\\s-+\\([a-zA-Z][a-zA-Z0-9-]*\\)"
     (1 font-lock-type-face))

    ;; Branch names
    (":as\\s-+\\([a-zA-Z][a-zA-Z0-9-]*\\)"
     (1 font-lock-variable-name-face))

    ;; Input bindings: (name "path")
    ("(inputs\\_>" . font-lock-keyword-face)
    ("(\\([a-zA-Z][a-zA-Z0-9-]*\\)\\s-+\"[^\"]+\")"
     (1 font-lock-variable-name-face))

    ;; Numbers
    ("\\b[0-9]+\\(?:\\.[0-9]+\\)?\\b" . font-lock-constant-face)

    ;; Operators
    (,(regexp-opt '("+" "-" "*" "/" ">" "<" ">=" "<=" "=") 'symbols)
     . font-lock-builtin-face)

    ;; Special variables (*name*)
    ("\\*[a-zA-Z][a-zA-Z0-9-]*\\*" . font-lock-variable-name-face)

    ;; Predicates (name?)
    ("\\b[a-zA-Z][a-zA-Z0-9-]*\\?" . font-lock-function-name-face)

    ;; Mutators (name!)
    ("\\b[a-zA-Z][a-zA-Z0-9-]*!" . font-lock-warning-face))
  "Font-lock keywords for `btscript-mode'.")

;; Indentation
(defun btscript-indent-line ()
  "Indent current line as BtScript code."
  (interactive)
  (let ((indent (btscript-calculate-indent)))
    (when indent
      (indent-line-to indent))))

(defun btscript-calculate-indent ()
  "Calculate indentation for current line."
  (save-excursion
    (beginning-of-line)
    (if (bobp)
        0
      (let ((not-indented t)
            (cur-indent 0))
        (cond
         ;; Closing paren - match opening
         ((looking-at "^[ \t]*)")
          (forward-char 1)
          (backward-sexp 1)
          (setq cur-indent (current-column)))
         ;; Otherwise, find enclosing form
         (t
          (save-excursion
            (condition-case nil
                (progn
                  (backward-up-list 1)
                  (setq cur-indent (+ (current-column) btscript-indent-offset)))
              (error (setq cur-indent 0))))))
        cur-indent))))

;; Keymap
(defvar btscript-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map lisp-mode-shared-map)
    map)
  "Keymap for `btscript-mode'.")

;; Imenu support
(defvar btscript-imenu-generic-expression
  '(("Flows" "^(flow\\s-+:id\\s-+\\([a-zA-Z][a-zA-Z0-9-]*\\)" 1)
    ("Functions" "^(def\\(?:ine\\)?\\s-+(\\([a-zA-Z][a-zA-Z0-9-?!*]*\\)" 1)
    ("Variables" "^(def\\s-+\\([a-zA-Z][a-zA-Z0-9-?!*]*\\)\\s-+[^(]" 1)
    ("Macros" "^(defmacro\\s-+\\([a-zA-Z][a-zA-Z0-9-?!*]*\\)" 1))
  "Imenu expressions for BtScript.")

;;;###autoload
(define-derived-mode btscript-mode prog-mode "BtScript"
  "Major mode for editing BtScript files.

\\{btscript-mode-map}"
  :syntax-table btscript-mode-syntax-table
  :group 'btscript

  ;; Comments
  (setq-local comment-start "; ")
  (setq-local comment-start-skip ";+\\s-*")
  (setq-local comment-end "")

  ;; Font-lock
  (setq-local font-lock-defaults '(btscript-font-lock-keywords))

  ;; Indentation
  (setq-local indent-line-function #'btscript-indent-line)
  (setq-local indent-tabs-mode nil)

  ;; Parens
  (setq-local parse-sexp-ignore-comments t)

  ;; Imenu
  (setq-local imenu-generic-expression btscript-imenu-generic-expression)

  ;; Electric pairs
  (setq-local electric-pair-pairs '((?\( . ?\))
                                     (?\[ . ?\])
                                     (?\" . ?\"))))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.bts\\'" . btscript-mode))

(provide 'btscript-mode)

;;; btscript-mode.el ends here
