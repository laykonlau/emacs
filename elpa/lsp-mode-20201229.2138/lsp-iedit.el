;;; lsp-iedit.el --- `iedit' integration -*- lexical-binding: t -*-
;;
;; Copyright (C) 2020 emacs-lsp maintainers
;;
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

;; This module provides features that allow starting `iedit' on various
;; different lsp-based, semantic units (like documentHighlights, and
;; linkedEditingRanges in the future).

;;; Code:

(require 'lsp-mode)

(declare-function iedit-make-occurrence-overlay "iedit-lib" (begin end))
(declare-function iedit-start-buffering "iedit-lib" ())

(defvar iedit-mode)
(defvar iedit-auto-buffering)
(defvar iedit-occurrences-overlays)

(defun lsp-iedit--on-ranges (ranges)
  "Start an `iedit' operation using RANGES.
RANGES shall be a list of lsp-`&Range's. They can be acquired
from various lsp protocol requests, e.g.
`textDocument/documentHighlight', ...."
  (require 'iedit)
  (unless (seq-empty-p ranges)
    (mapc (-lambda ((&RangeToPoint :start :end))
            (push (iedit-make-occurrence-overlay start end)
                  iedit-occurrences-overlays))
          ranges)
    ;; See `iedit-start'; TODO: upstream this
    (setq iedit-mode t)
    (when iedit-auto-buffering
      (iedit-start-buffering))
    (run-hooks 'iedit-mode-hook)
    (add-hook 'before-revert-hook 'iedit-done nil t)
    (add-hook 'kbd-macro-termination-hook 'iedit-done nil t)
    (add-hook 'change-major-mode-hook 'iedit-done nil t)
    (add-hook 'iedit-aborting-hook 'iedit-done nil t)
    (message "%d occurrences of \"%s\""
             (seq-length ranges)
             (lsp--range-text (lsp-seq-first ranges)))))

;;;###autoload
(defun lsp-iedit-highlights ()
  "Start an `iedit' operation on the documentHighlights at point.
This can be used as a primitive `lsp-rename' replacement if the
language server doesn't support renaming.

See also `lsp-enable-symbol-highlighting'."
  (interactive)
  (let ((highlights (lsp-request "textDocument/documentHighlight"
                                 (lsp--text-document-position-params))))
    (lsp-iedit--on-ranges (mapcar #'lsp:document-highlight-range highlights))))

(provide 'lsp-iedit)
;;; lsp-iedit.el ends here
