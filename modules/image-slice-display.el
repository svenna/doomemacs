;;; image-slice-display.el --- Generic sliced image display -*- lexical-binding: t; -*-

;;; Commentary:
;; Displays an image as horizontal slices, one per buffer line.
;; Follows the org-sliced-images pattern: real dummy lines for Evil
;; compatibility, line-height t on newlines to eliminate gaps.

;;; Code:

(require 'cl-lib)

;; --- Data structure ---

(cl-defstruct (image-slice-display-group
               (:constructor image-slice-display--make-group))
  buffer
  overlays
  dummy-positions
  lh-positions)

;; --- Undo protection ---

(defmacro image-slice-display--without-undo (&rest body)
  "Execute BODY without recording undo information."
  (declare (indent 0))
  (let ((saved (make-symbol "saved-undo")))
    `(let ((,saved buffer-undo-list))
       (buffer-disable-undo)
       (unwind-protect
           (progn ,@body)
         (buffer-enable-undo)
         (setq buffer-undo-list ,saved)))))

;; --- Helpers ---

(defun image-slice-display--line-bols (beg end)
  "Return list of line-beginning positions in [BEG, END)."
  (let (bols)
    (save-excursion
      (goto-char beg)
      (while (< (point) end)
        (push (line-beginning-position) bols)
        (forward-line 1)))
    (nreverse bols)))

(defun image-slice-display--set-lh (bol)
  "Set line-height t on the newline at end of line starting at BOL."
  (save-excursion
    (goto-char bol)
    (let ((nl (line-end-position)))
      (when (< nl (point-max))
        (put-text-property nl (1+ nl) 'line-height t))))
  bol)

(defun image-slice-display--insert-dummies (after-pos count)
  "Insert COUNT dummy lines after AFTER-POS. Returns list of their bols."
  (let (inserted-bols)
    (save-excursion
      (goto-char after-pos)
      (end-of-line)
      (dotimes (_ count)
        (insert (propertize "\n" 'line-height t))
        (let ((bol (line-beginning-position)))
          (insert " ")
          (push bol inserted-bols))))
    (nreverse inserted-bols)))

;; --- Public API ---

;;;###autoload
(defun image-slice-display-show (region-beg region-end image-file display-width)
  "Display IMAGE-FILE as sliced overlays over the region.
Returns a group struct for later removal."
  (let* ((img (create-image image-file 'png nil :width display-width :ascent 'center))
         (img-px-h (cdr (image-size img t)))
         (font-h (default-font-height))
         (n-slices (max 1 (ceiling (/ (float img-px-h) font-h))))
         (dy (/ (float font-h) img-px-h))
         (existing-bols (image-slice-display--line-bols region-beg region-end))
         (n-existing (length existing-bols))
         (shortfall (max 0 (- n-slices n-existing)))
         (buf (current-buffer))
         (all-overlays nil)
         (dummy-positions nil)
         (lh-positions nil))

    ;; Step 1: Insert dummy lines if needed
    (when (> shortfall 0)
      (image-slice-display--without-undo
        (let ((last-bol (car (last existing-bols))))
          (setq dummy-positions
                (image-slice-display--insert-dummies last-bol shortfall))
          (setq existing-bols (append existing-bols dummy-positions)))))

    ;; Step 2: Set line-height t on all newlines in slice area
    (image-slice-display--without-undo
      (dotimes (i n-slices)
        (let ((bol (nth i existing-bols)))
          (when bol
            (push (image-slice-display--set-lh bol) lh-positions)))))

    ;; Step 3: Create slice overlays (bol to eol, NOT covering newline)
    (dotimes (i n-slices)
      (let* ((bol (nth i existing-bols))
             (eol (save-excursion (goto-char bol) (line-end-position)))
             ;; Don't cover the newline — covering it causes horizontal shift.
             ;; Empty lines (bol==eol) will show as blank gaps but this is
             ;; the only approach that renders without horizontal misalignment.
             (ov-end eol)
             (y-frac (/ (* (float i) font-h) img-px-h))
             (ov (make-overlay bol ov-end buf)))
        (overlay-put ov 'display
                     (list (list 'slice 0 y-frac 1.0 dy) img))
        (overlay-put ov 'face 'default)
        (overlay-put ov 'evaporate t)
        (overlay-put ov 'image-slice-display t)
        (push ov all-overlays)))

    ;; Step 4: Hide excess lines
    (when (> n-existing n-slices)
      (dolist (bol (nthcdr n-slices existing-bols))
        (unless (member bol dummy-positions)
          (let* ((eol (save-excursion (goto-char bol) (line-end-position)))
                 (ov (make-overlay bol eol buf)))
            (overlay-put ov 'display "")
            (overlay-put ov 'evaporate t)
            (overlay-put ov 'image-slice-display t)
            (push ov all-overlays)))))

    ;; Return group
    (image-slice-display--make-group
     :buffer buf
     :overlays (nreverse all-overlays)
     :dummy-positions dummy-positions
     :lh-positions (nreverse lh-positions))))

;;;###autoload
(defun image-slice-display-remove (group)
  "Remove sliced image display and restore buffer."
  (when (image-slice-display-group-p group)
    (let ((buf (image-slice-display-group-buffer group)))
      (when (buffer-live-p buf)
        (with-current-buffer buf
          ;; 1. Remove overlays
          (dolist (ov (image-slice-display-group-overlays group))
            (when (overlay-buffer ov)
              (delete-overlay ov)))

          ;; 2. Remove dummy lines (reverse order)
          (image-slice-display--without-undo
            (dolist (pos (nreverse
                          (copy-sequence
                           (image-slice-display-group-dummy-positions group))))
              (save-excursion
                (goto-char pos)
                (let ((bol (line-beginning-position))
                      (next (1+ (line-end-position))))
                  (delete-region (1- bol) (min next (point-max)))))))

          ;; 3. Remove line-height properties
          (image-slice-display--without-undo
            (dolist (bol (image-slice-display-group-lh-positions group))
              (save-excursion
                (goto-char bol)
                (let ((nl (line-end-position)))
                  (when (< nl (point-max))
                    (remove-text-properties nl (1+ nl) '(line-height nil))))))))))))

(provide 'image-slice-display)
;;; image-slice-display.el ends here
