;;; breadcrumb.el --- Breadcrumb.  Set breadcrumb bookmarks and jump to them.
;;
;; Copyright (C) 2004-2008 William W. Wong
;; Copyright (C) 2010 Philip Weaver - philip(dot)weaver(at)gmail(dot)com
;;
;; Author: William W. Wong <williamw520(AT)yahoo(DOT)com>
;; Created: October, 2004
;; Version: 1.1.4
;; Keywords: breadcrumb, quick, bookmark, bookmarks

;; This file is not part of GNU Emacs.

;;; License
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License version 2 as
;; published by the Free Software Foundation.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
;;

;; See README.org for more information.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Private section
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;; Program global variables:

(defvar *bc-bookmarks* ()
  "List of bookmarks and their records.
The list is (Bookmark1 Bookmark2 ...) where each Bookmark is (TYPE FILENAME . POSITION)"
  )

(defvar *bc-current* 0
  "The current bookmark.  `bc-next' and `bc-previous' would use this as the starting point."
  )

(defvar *bc-bookmark-just-added* nil
  "Flag indicates a bookmark has just been added.  `bc-next' and `bc-previous' use this to determine whether to increment or decrement."
  )

;;; Buffer type constants

(defconst bc--type-unsupported  'unsupported)
(defconst bc--type-file         'file)
(defconst bc--type-dired        'dired)
(defconst bc--type-info         'info)
(defconst bc--type-system       'system)

;;; Constants
(defconst bc--menu-buffer       "*Breadcrumb Bookmarks*")
(defconst bc--file-magic        "WBC")
(defconst bc--file-version      1)
(defconst bc--menu-table-offset 7)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Public section
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; User Configuration Variables

(defgroup breadcrumb nil
  "Setting breadcrumb bookmarks and jumping to them."
  :link '(emacs-library-link :tag "Source Lisp File" "breadcrumb.el")
  :group 'editing
  :prefix "bc-")

(defcustom bc-switch-buffer-func 'switch-to-buffer
  "*Function to use to switch to a buffer"
  :group 'breadcrumb)

(defcustom bc-bookmark-limit 16
  "*Maximum numbers of breadcrumb bookmarks to keep in the queue."
  :type 'integer
  :group 'breadcrumb)

(defcustom bc-bookmark-file (expand-file-name "~/.breadcrumb")
  "*Filename to store bookmarks across Emacs sessions.  If nil the bookmarks will not be saved."
  :type 'string
  :group 'breadcrumb)

(defcustom bc-bookmark-hook-enabled t
  "*Set bookmark automatically on find-tag and tags-search."
  :type 'boolean
  :group 'breadcrumb)


;;; User callable functions
;;;###autoload
(defun bc-set ()
  "Set a bookmark at the current buffer and current position."
  (interactive)
  (let ((type (bc-get-buffer-type)))
    (if (eq type bc--type-unsupported)
        (message "breadcrumb does not support the current buffer type.")
      (let ((filename (bc-get-buffer-filename type))
            (position (bc-get-buffer-position type)))
        (if (or (null filename) (null position))
            (message "Can't get filename or position of the current buffer.")
          ;; Create a bookmark record and add it to the bookmark list.
          (bc-bookmarks-add (bc-bookmark-new type filename position))
          (setq *bc-current* 0)
          (setq *bc-bookmark-just-added* t)
          (message "breadcrumb bookmark is set for the current position.")
          ))))
  )

;;;###autoload
(defun bc-previous ()
  "Jump to the previous bookmark."
  (interactive)
  (if *bc-bookmark-just-added*
      (setq *bc-bookmark-just-added* nil)
    (bc-advance-current 'bc-bookmarks-increment))
  (bc-jump (bc-bookmarks-get *bc-current*))
  )

;;;###autoload
(defun bc-next ()
  "Jump to the next bookmark."
  (interactive)
  (if *bc-bookmark-just-added*
      (setq *bc-bookmark-just-added* nil)
    (bc-advance-current 'bc-bookmarks-decrement))
  (bc-jump (bc-bookmarks-get *bc-current*))
  )

;;;###autoload
(defun bc-local-previous ()
  "Jump to the previous bookmark in the local buffer."
  (interactive)
  (if *bc-bookmark-just-added*
      (setq *bc-bookmark-just-added* nil))
  (if (bc-local-advance-current 'bc-bookmarks-increment)
      (bc-jump (bc-bookmarks-get *bc-current*))
    (message "No breadcrumb bookmark set in local buffer."))
  )

;;;###autoload
(defun bc-local-next ()
  "Jump to the next bookmark in the local buffer."
  (interactive)
  (if *bc-bookmark-just-added*
      (setq *bc-bookmark-just-added* nil))
  (if (bc-local-advance-current 'bc-bookmarks-decrement)
      (bc-jump (bc-bookmarks-get *bc-current*))
    (message "No breadcrumb bookmark set in local buffer."))
  )

;;;###autoload
(defun bc-goto-current ()
  "Jump to the current bookmark."
  (interactive)
  (bc-jump-to *bc-current*)
  )

;;;###autoload
(defun bc-clear ()
  "Clear all the breadcrumb bookmarks in the queue."
  (interactive)
  (setq *bc-bookmarks* ())
  (setq *bc-current* 0)
  )

;;;###autoload
(defun bc-list (&optional other-window-p)
  "Display the breadcrumb bookmarks in the buffer `*Breadcrumb Bookmarks*' to
allow interactive management of them.  Argument OTHER-WINDOW-P means to select
other buffer in other window."
  (interactive "P")
  (if other-window-p
      (switch-to-buffer-other-window (get-buffer-create bc--menu-buffer))
    (switch-to-buffer (get-buffer-create bc--menu-buffer)))
  (bc-menu-redraw)
  (goto-char (point-min))
  (forward-line bc--menu-table-offset)
  (bc-menu-mode)
  )

;;;###autoload
(defun bc-delete-current ()
  "Delete the last bookmark."
  (interactive)
  (setq *bc-bookmarks* (remove (bc-bookmarks-get *bc-current*) *bc-bookmarks*))
  )

(defun bc-bookmark-to-register (register &optional index)
  "Save breadcrumb bookmark at index INDEX to register REGISTER.

If INDEX is nil, then use the most recently jumped to bookmark,
as indicated by `*bc-current*'"
  (interactive "cBookmark to register: ")
  (let* ((bookmark (or (bc-bookmarks-get (bc-menu-get-bookmark-index))
                       (bc-bookmarks-get (or index *bc-current*))))
         (type (bc-bookmark-type bookmark))
         (filename (bc-bookmark-filename bookmark))
         (position (bc-bookmark-position bookmark))
         (buffer (cond ((or (eq type bc--type-file)
                            (eq type bc--type-dired))
                        (find-buffer-visiting filename))

                       ((eq type bc--type-system) filename)

                       ((eq type bc--type-info) nil)
                       ;; TODO?
                       ;; (eval-when-compile (require 'info))
                       ;; (save-excursion
                       ;;   (Info-find-node filename (car position))
                       ;;   (goto-char (cdr position))
                       ;;   (point-to-register register))

                       ((eq type bc--type-unsupported)
                        (error "Unsupported bookmark type"))
                       (t (error "Unknown bookmark type")))))

;; I had to use both `with-current-buffer' and `save-excursion' to get this to
;; work.  Without `with-current-buffer' we end up jumping to the bookmark if
;; this is called from the bc menu, and without `save-excursion' we end up
;; jumping to the point if it's in the same buffer

    (if buffer
        (with-current-buffer buffer
          (save-excursion
            (goto-char position)
            (point-to-register register)))
      (set-register register (list 'file-query filename position)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Bookmark record functions

(defun bc-bookmark-new (type filename position)
  "Construct a bookmark record, saving its file and position in the bookmark list.
TYPE the type of the buffer to bookmark ('file or 'info)
FILENAME filename of the breadcrumb bookmark.
POSITION the positio of the breadcrumb bookmark."
  (cons type (cons filename position)))

(defun bc-bookmark-type (bookmark)
  (car bookmark)
  )

(defun bc-bookmark-filename (bookmark)
  (car (cdr bookmark))
  )

(defun bc-bookmark-position (bookmark)
  (cdr (cdr bookmark))
  )

(defun bc-bookmarks-add (bookmark)
  "Add a bookmark record."
  ;; Remove existing duplicate bookmark.
  (setq *bc-bookmarks* (remove bookmark *bc-bookmarks*))
  (bc-bookmarks-make-room)
  (setq *bc-bookmarks* (cons bookmark *bc-bookmarks*))
  )

(defun bc-bookmarks-make-room ()
  "Make sure the bookmark list not exceeding limit.  Remove the last item if exceeded."
  (if (>= (length *bc-bookmarks*) bc-bookmark-limit)
      ;; Remove last item from list
      (setq *bc-bookmarks* (reverse (cdr (reverse *bc-bookmarks*))))
    ))

(defun bc-bookmarks-get (index)
  "Get a bookmark record from the list based on its index.
INDEX the bookmark index (0-based) into the bookmark queue."
  (if (or (< index 0) (>= index (length *bc-bookmarks*)))
      nil
    (let ((bookmark nil)
          (list1 *bc-bookmarks*))
      (while (>= index 0)
        (setq bookmark (car list1))
        (setq list1 (cdr list1))
        (setq index (1- index)))
      bookmark))
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Bookmark current position functions

(defun bc-bookmarks-increment (index)
  "Return the increment of the input index.  Wrap around when reaching end of *bc-bookmarks*."
  (setq index (1+ index))
  (if (< index (length *bc-bookmarks*))
      index
    0)
  )

(defun bc-bookmarks-decrement (index)
  "Return the decrement of the input index.  Wrap around when reaching beginning of *bc-bookmarks*."
  (setq index (1- index))
  (if (>= index 0)
      index
    (if (= (length *bc-bookmarks*) 0)
        0
      (1- (length *bc-bookmarks*))))
  )

(defun bc-advance-current (incremental-func)
  "Increment or decrement the current index '*bc-current*' based on the 'incremental-func' parameter."
  (setq *bc-current* (funcall incremental-func *bc-current*))
  )

(defun bc-local-advance-current (incremental-func)
  "Increment the current index '*bc-current*'."
  (let ((buffer-type (bc-get-buffer-type))
        (buffer-filename (bc-get-buffer-filename (bc-get-buffer-type)))
        (buffer-bookmark-index)
        (next-index nil)
        )
    (setq buffer-bookmark-index (bc-bookmarks-find-by buffer-type buffer-filename))
    (if (null buffer-bookmark-index)
        ;; Current buffer has no bookmark.  Don't do any jumping.
        nil
      (setq next-index (bc-bookmarks-circular-find-by
                        incremental-func *bc-current* buffer-type buffer-filename))
      (if (= next-index -1)
          nil
        (setq *bc-current* next-index)
        )
      )
    )
  )

(defun bc-bookmarks-find-by (type filename)
  "Find any bookmark matching type and filename.  Return the first matching one.  Return nil if not found."
  (let ((index 0)
        (bookmark-index nil))
    (mapc
     (lambda (bookmark)
       (if (and (null bookmark-index)
                (equal type (bc-bookmark-type bookmark))
                (equal filename (bc-bookmark-filename bookmark)))
           (setq bookmark-index index))
       (setq index (1+ index))
       )
     *bc-bookmarks*
     )
    bookmark-index
    )
  )

(defun bc-bookmarks-circular-find-by (incremental-func starting-index type filename)
  "Find the next bookmark matching type and filename after the starting-index.
Return the first matching index.  Return -1 if not found."
  (let (index bookmark)
    (catch 'done
      (setq index (funcall incremental-func starting-index))
      (while t
        (setq bookmark (bc-bookmarks-get index))
        (if (and (equal type (bc-bookmark-type bookmark))
                 (equal filename (bc-bookmark-filename bookmark)))
            (throw 'done index)
            )
        (if (= index starting-index)
            ;; Wrap around to starting-index again.  Exit.  Not found.
            (throw 'done -1)
            )
        (setq index (funcall incremental-func index))
        )
      )
    )
  )

(defun bc-jump-to (bookmark-index &optional switch-buffer-func)
  "Jump to a bookmark based on the bookmark-index."
  (let ((bookmark (bc-bookmarks-get bookmark-index)))
    (when (not(null bookmark))
      (setq *bc-bookmark-just-added* nil)
      (setq *bc-current* bookmark-index)
      (bc-jump bookmark switch-buffer-func)
      ))
  )

(defun bc-jump (bookmark &optional switch-buffer-func)
  "Jump to a bookmark.
BOOKMARK is the bookmark to jump to, which has the form (FILENAME . POSITION)."
  (if (null bookmark)
      (message "No breadcrumb bookmark set.")
    (let ((type (bc-bookmark-type bookmark))
          (filename (bc-bookmark-filename bookmark))
          (position (bc-bookmark-position bookmark)))
      (if (null switch-buffer-func)
          (setq switch-buffer-func bc-switch-buffer-func))
      (cond
       ((or (eq type bc--type-file)
            (eq type bc--type-dired))
        (funcall switch-buffer-func (find-file-noselect filename))
        (goto-char position))
       ((eq type bc--type-info)
        (eval-when-compile (require 'info))
        (Info-find-node filename (car position))
        (goto-char (cdr position)))
       ((eq type bc--type-system)
        (funcall switch-buffer-func filename)
        (goto-char position))
       ((eq type bc--type-unsupported)
        (error "Unsupported bookmark type"))
       (t (error "Unknown bookmark type")))
      )
    )
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Get bookmark information from the current buffer

(defun bc-get-buffer-type ()
  "Get the type of the current buffer."
  (cond
   ((eq major-mode 'Info-mode) bc--type-info)
   ((buffer-file-name) bc--type-file)
   ((and (boundp 'dired-directory) dired-directory) bc--type-dired)
   ((string= (substring (buffer-name) 0 1) "*") bc--type-system)
   (t bc--type-unsupported)))

(defun bc-get-buffer-filename (type)
  "Get the current buffer's filename."
  (cond
    ((eq type bc--type-info)    Info-current-file)
    ((eq type bc--type-file)    (buffer-file-name))
    ((eq type bc--type-dired)   (if (stringp dired-directory)
                                    dired-directory
                                    (car dired-directory)))
    ((eq type bc--type-system)  (buffer-name))
    (t nil)))

(defun bc-get-buffer-position (type)
  "Get the position of the current buffer.
It's the position (point) for normal buffer and (info-node-name point) for Info buffer."
  (cond
    ((eq type bc--type-info)    (cons Info-current-node (point)))
    ((eq type bc--type-file)    (point))
    ((eq type bc--type-dired)   (point))
    ((eq type bc--type-system)  (point))
    (t nil)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; *Breadcrumb Bookmark* menu functions

(defun bc-revert-buffer (&optional ignore-auto noconfirm)
  (let ((line (line-number-at-pos (point))))
    (bc-menu-redraw)
    (goto-char (point-min))
    (forward-line (1- line))))

(defun bc-menu-redraw ()
  "Redraw the breadcrumb bookmarks in the buffer named `*Breadcrumb Bookmarks*'."
  (save-excursion
    (save-window-excursion
      (let ((index 0))
        (toggle-read-only 0)
        (erase-buffer)
        (insert "*Breadcrumb Bookmarks*\n\n")
        (insert "Bookmarks listed in most recently set order.  Press '?' for help.\n")
        (insert "The bookmark preceded by a \">\" is the last jump-to bookmark.\n\n")
        (insert "% Type    Position      Buffer\n")
        (insert "- ------- ------------  ---------------------------------\n")
        (mapc
         (lambda (bookmark)
           (insert (format " %s%-7s %-12s  %s\n"
                           (cond ((eq index *bc-current*) ">") (t " "))
                           (symbol-name (bc-bookmark-type bookmark))
                           (bc-bookmark-position-to-str bookmark)
                           (bc-bookmark-filename bookmark)))
           (setq index (1+ index))
           )
         *bc-bookmarks*)
        (toggle-read-only 1)
        )))
  )

(defun bc-bookmark-position-to-str (bookmark)
  (let ((type (bc-bookmark-type bookmark))
        (position (bc-bookmark-position bookmark)))
    (cond
      ((eq type bc--type-info)   (format "%s %d" (car position) (cdr position)))
      ((eq type bc--type-file)   (number-to-string position))
      ((eq type bc--type-dired)  (number-to-string position))
      ((eq type bc--type-system) (number-to-string position))
      (t (number-to-string position))))
  )

(defun bc-menu-get-bookmark-index ()
  "Return a bookmark index under the cursor.  Index might be out of range."
  (1- (- (line-number-at-pos) bc--menu-table-offset))
  )

(defun bc-menu-valid-bookmark ()
  "Check whether the cursor is on a valid bookmark"
  (not (null (bc-bookmarks-get (bc-menu-get-bookmark-index))))
  )

(defun bc-menu-jump ()
  "Jump to the bookmark under cursor."
  (interactive)
  (when (bc-menu-valid-bookmark)
    (let ((bookmark-index (bc-menu-get-bookmark-index)))
      (generic-close-buffer)
      (bc-jump-to bookmark-index)
      ))
  )

(defun bc-menu-advance-cursor ()
  (forward-line 1)
  (when (null (bc-menu-valid-bookmark))
    (goto-char (point-min))
    (forward-line bc--menu-table-offset))
  )

(defun bc-menu-visit-other ()
  "Visit the bookmark under cursor in the other window."
  (interactive)
  (when (bc-menu-valid-bookmark)
    ;; Visit the bookmark's buffer in the other window
    (bc-jump-to (bc-menu-get-bookmark-index) 'switch-to-buffer-other-window)
    ;; Switch back to the Breadcrumb Bookmark Menu's buffer
    (switch-to-buffer-other-window (get-buffer bc--menu-buffer))
    (bc-menu-advance-cursor)
    )
  )

(defun bc-menu-mark-char (mark-char)
  "Set a mark char on the bookmark line at cursor."
  (when (bc-menu-valid-bookmark)
    (toggle-read-only 0)
    (beginning-of-line)
    (delete-char 1)
    (insert mark-char)
    (bc-menu-advance-cursor)
    (toggle-read-only 1)
  ))

(defun bc-menu-mark-all-char (mark-char)
  "Set a mark char for all of the bookmark lines."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (forward-line bc--menu-table-offset)
    (dotimes (i (length *bc-bookmarks*))
      (bc-menu-mark-char mark-char)
      ))
  )

(defun bc-menu-mark-delete ()
  "Mark the bookmark at cursor for delete."
  (interactive)
  (bc-menu-mark-char "D")
  )

(defun bc-menu-unmark-delete ()
  "Unmark the bookmark at cursor from deletion."
  (interactive)
  (bc-menu-mark-char " ")
  )

(defun bc-menu-mark-all-delete ()
  "Mark all of the bookmarks for delete."
  (interactive)
  (bc-menu-mark-all-char "D")
  )

(defun bc-menu-unmark-all-delete ()
  "Unmark all of the bookmarks from delete."
  (interactive)
  (bc-menu-mark-all-char " ")
  )

(defun bc-menu-commit-deletions ()
  "Commit deletion on the marked bookmarks."
  (interactive)
  (goto-char (point-min))
  (forward-line bc--menu-table-offset)
  (let ((items-to-delete (list)))
    (dotimes (i (length *bc-bookmarks*))
      (beginning-of-line)
      (if (looking-at "D")
          (push i items-to-delete))
      (forward-line 1))
    (dolist (index items-to-delete)
      (let ((bookmark (bc-bookmarks-get index)))
        (setq *bc-bookmarks* (remove bookmark *bc-bookmarks*))))
    )
  (bc-menu-redraw)
  (forward-line bc--menu-table-offset)
  )

(defvar *bc-menu-mode-map* nil)
(progn
  (setq *bc-menu-mode-map* (make-keymap))
  (suppress-keymap *bc-menu-mode-map* t)
  (define-key *bc-menu-mode-map* "q"        'generic-close-buffer)
  (define-key *bc-menu-mode-map* "j"        'bc-menu-jump)
  (define-key *bc-menu-mode-map* "\C-m"     'bc-menu-jump)
  (define-key *bc-menu-mode-map* "v"        'bc-menu-visit-other)
  (define-key *bc-menu-mode-map* "d"        'bc-menu-mark-delete)
  (define-key *bc-menu-mode-map* "\C-d"     'bc-menu-mark-all-delete)
  (define-key *bc-menu-mode-map* "u"        'bc-menu-unmark-delete)
  (define-key *bc-menu-mode-map* "\C-u"     'bc-menu-unmark-all-delete)
  (define-key *bc-menu-mode-map* "x"        'bc-menu-commit-deletions)
  (define-key *bc-menu-mode-map* "n"        'next-line)
  (define-key *bc-menu-mode-map* " "        'next-line)
  (define-key *bc-menu-mode-map* "p"        'previous-line)
  (define-key *bc-menu-mode-map* "?"        'describe-mode)
  (define-key *bc-menu-mode-map* "g"        'revert-buffer)
  (define-key *bc-menu-mode-map* "/"        'bc-bookmark-to-register)
  )

(defun bc-menu-mode ()
  "Major mode for listing and editing the list of breadcrumb bookmarks.
The following commands are available.
\\<*bc-menu-mode-map*>
\\[bc-menu-jump] -- jump to the bookmark under the cursor.
\\[bc-menu-visit-other] -- visit the bookmark's buffer in the other window.
\\[bc-menu-mark-delete] -- mark this bookmark to be deleted.
\\[bc-menu-mark-all-delete] -- mark all bookmarks to be deleted.
\\[bc-menu-unmark-delete] -- unmark the bookmark from deletion.
\\[bc-menu-unmark-all-delete] -- unmark all bookmarks from deletion.
\\[bc-menu-commit-deletions] -- delete bookmarks marked with `\\[bc-menu-mark-delete]'.
\\[next-line] -- move to the next line
\\[previous-line] -- move to the previous line
\\[generic-close-buffer] -- close the *Breadcrumb Bookmarks* window
"
  (kill-all-local-variables)
  (use-local-map *bc-menu-mode-map*)
  (setq truncate-lines t)
  (setq buffer-read-only t)
  (setq major-mode 'bc-menu-mode)
  (setq mode-name "Breadcrumb Bookmark Menu")
  (set (make-local-variable 'revert-buffer-function) #'bc-revert-buffer)
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Bookmark saving and restoring

(defun bc-bookmarks-save ()
  "Save the bookmarks to file."
  (let ((data-alist
         (list
          (cons 'magic-number bc--file-magic)
          (cons 'version bc--file-version)
          (cons 'timestamp (current-time))
          (cons '*bc-current* *bc-current*)
          (cons '*bc-bookmark-just-added* *bc-bookmark-just-added*)
          (cons '*bc-bookmarks* *bc-bookmarks*))
          ))
    (bc-bookmarks-save-file data-alist bc-bookmark-file))
  )

(defun bc-bookmarks-restore ()
  "Load the bookmarks from file."
  (let ((data-alist (bc-bookmarks-load-file bc-bookmark-file)))
    (when (equal bc--file-magic (cdr (assoc 'magic-number data-alist)))
      (setq *bc-current* (cdr (assoc '*bc-current* data-alist)))
      (setq *bc-bookmark-just-added* (cdr (assoc '*bc-bookmark-just-added* data-alist)))
      (setq *bc-bookmarks* (cdr (assoc '*bc-bookmarks* data-alist)))
      ))
  )

(defun bc-bookmarks-load-file (file)
  "Load the data-list from file."
  (when (and file
             (file-readable-p file))
    (let ((loading-buffer (find-file-noselect file))
          (bookmark-list))
      (setq bookmark-list (with-current-buffer loading-buffer
                            (goto-char (point-min))
                            (read (current-buffer))))
      (kill-buffer loading-buffer)
      bookmark-list))
  )

(defun bc-bookmarks-save-file (data-alist file)
  "Save the data-alist to file."
  (when (and file
             (file-writable-p file))
    (let ((writing-buffer (find-file-noselect file)))
      (with-current-buffer writing-buffer
        (erase-buffer)
        (insert ";; breadcrumb.el saved bookmarks.  Do not edit this file.\n")
        (prin1 data-alist (current-buffer))
        (insert "\n")
        (save-buffer))
      (kill-buffer writing-buffer)))
  )

;; Load from file on start up.
(add-hook' after-init-hook 'bc-bookmarks-restore)

;; Save to file on exit.
(add-hook 'kill-emacs-hook 'bc-bookmarks-save)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Advice hooks to set breadcrumb bookmark on find-tag, tags-search, etc.

(defadvice find-tag (before bc-tag activate compile)
  "Intercept find-tag to save a breadcrumb bookmark before jumping to tag."
  (if bc-bookmark-hook-enabled
      (bc-set))
  )

(defadvice tags-search (before bc-tag activate compile)
  "Intercept tags-search to save a breadcrumb bookmark before jumping to tag."
  (if bc-bookmark-hook-enabled
      (bc-set))
  )

(defadvice query-replace (before bc-tag activate compile)
  "Intercept query-replace to save a breadcrumb bookmark before doing the replacement."
  (if bc-bookmark-hook-enabled
      (bc-set))
  )


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 3rd party util functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(unless (fboundp 'line-number-at-pos)
  (defun line-number-at-pos (&optional pos)
    "Return (narrowed) buffer line number at position POS.
If POS is nil, use current buffer location."
    (let ((opoint (or pos (point))) start)
      (save-excursion
        (goto-char (point-min))
        (setq start (point))
        (goto-char opoint)
        (forward-line 0)
        (1+ (count-lines start (point)))))))

(defun generic-close-buffer ()
  "Make closing buffer work for both Emacs and XEmacs"
  (interactive)
  (if (fboundp 'quit-window)
      (quit-window)
    (bury-buffer))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(provide 'breadcrumb)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; breadcrumb.el ends here
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

