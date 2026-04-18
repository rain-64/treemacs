;;; treemacs-unfocused-hl-line-mode.el --- Dim the treemacs hl-line when unfocused -*- lexical-binding: t -*-

;; Copyright (C) 2026 Alexander Miller

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Minor mode that swaps the selected-line highlight in treemacs buffers
;; to `treemacs-hl-line-unfocused-face' whenever the treemacs window is
;; not the selected window, and restores `treemacs-hl-line-face' when
;; the treemacs window regains focus.

;; NOTE: This module is lazy-loaded.

;;; Code:

(require 'face-remap)
(require 'treemacs-faces)

(eval-when-compile
  (require 'treemacs-macros))

(defvar-local treemacs--hl-line-unfocused-cookie nil
  "Face-remap cookie for the unfocused hl-line remap in this buffer.")

(defun treemacs--hl-line-remove-unfocused-remap ()
  "Remove the local unfocused hl-line remap in the current buffer, if any."
  (when treemacs--hl-line-unfocused-cookie
    (face-remap-remove-relative treemacs--hl-line-unfocused-cookie)
    (setq treemacs--hl-line-unfocused-cookie nil)))

(defun treemacs--hl-line-add-unfocused-remap ()
  "Add the unfocused hl-line remap to the current buffer."
  (unless treemacs--hl-line-unfocused-cookie
    (setq treemacs--hl-line-unfocused-cookie
          (face-remap-add-relative
           'hl-line 'treemacs-hl-line-unfocused-face))))

(defun treemacs--hl-line-update-focus (&rest _)
  "Reapply the unfocused hl-line face in all treemacs buffers.
Buffers whose window is not the currently selected window get the
unfocused remap added; buffers whose window is selected have it
removed.  Buffers without a live window are left alone."
  (treemacs-run-in-all-derived-buffers
   (let ((window (get-buffer-window (current-buffer) t)))
     (cond
      ((not (window-live-p window))
       nil)
      ((eq (frame-selected-window (window-frame window)) window)
       (treemacs--hl-line-remove-unfocused-remap))
      (t
       (treemacs--hl-line-add-unfocused-remap))))))

(defun treemacs--enable-unfocused-hl-line-mode ()
  "Setup for `treemacs-unfocused-hl-line-mode'."
  (add-hook 'window-selection-change-functions
            #'treemacs--hl-line-update-focus)
  (add-hook 'treemacs-mode-hook #'treemacs--hl-line-update-focus)
  (treemacs--hl-line-update-focus))

(defun treemacs--disable-unfocused-hl-line-mode ()
  "Teardown for `treemacs-unfocused-hl-line-mode'."
  (remove-hook 'window-selection-change-functions
               #'treemacs--hl-line-update-focus)
  (remove-hook 'treemacs-mode-hook #'treemacs--hl-line-update-focus)
  (treemacs-run-in-all-derived-buffers
   (treemacs--hl-line-remove-unfocused-remap)))

;;;###autoload
(define-minor-mode treemacs-unfocused-hl-line-mode
  "Minor mode to dim the treemacs hl-line when treemacs is not focused.

When enabled, the selected-line highlight in any treemacs buffer is
drawn with `treemacs-hl-line-unfocused-face' whenever the treemacs
window is not the selected window, and with `treemacs-hl-line-face'
when it is.  Useful in IDE-style layouts, where a visible but dimmer
cursor line in the sidebar makes it obvious at a glance which side
has keyboard focus without losing the indicator of which file the
cursor is on.

Customise `treemacs-hl-line-unfocused-face' to control what the
unfocused highlight looks like.

Requires `window-selection-change-functions', available since
Emacs 27.1."
  :init-value nil
  :global     t
  :lighter    nil
  :group      'treemacs
  (cond
   ((not treemacs-unfocused-hl-line-mode)
    (treemacs--disable-unfocused-hl-line-mode))
   ((not (boundp 'window-selection-change-functions))
    (setq treemacs-unfocused-hl-line-mode nil)
    (user-error "%s %s"
                "treemacs-unfocused-hl-line-mode is only available in Emacs"
                "versions that support `window-selection-change-functions'"))
   (t
    (treemacs--enable-unfocused-hl-line-mode))))

(provide 'treemacs-unfocused-hl-line-mode)

;;; treemacs-unfocused-hl-line-mode.el ends here
