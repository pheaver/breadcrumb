;;; breadcrumb.el --- Breadcrumb.  Set breadcrumb bookmarks and jump to them.
;;
;; Copyright (C) 2004-2008 William W. Wong
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
;;; Commentary:
;;
;; Some testing and debugging code for breadcrumb.el.  Just do this:
;;
;; (load "breadcrumb-test.el")
;;

(require 'breadcrumb)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Testing and debugging
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Testing
(eval-when-compile
 (bc-bookmarks-get 0)
 (bc-bookmarks-get 1)
 )

;;; Debugging with C-xC-e
(if nil
    (progn
      (global-set-key "\C-x\M-t"    'bc-dbgtest)
      (bc-next)
      (bc-previous)
      (bc-clear)
      (bc-list)
      *bc-bookmark-just-added*
      *bc-bookmarks*
      *bc-current*
      type
      filename
      position
      data-list
      (setq *bc-current* 0)
      (1- (length *bc-bookmarks*))
      (buffer-file-name)
      (bc-get-buffer-filename bc--type-file)
      (bc-get-buffer-position bc--type-file)
      (bc-bookmarks-load-file bc-bookmark-file)
      (bc-bookmarks-save-file *bc-bookmarks* bc-bookmark-file)
      (bc-bookmarks-save)
      (bc-bookmarks-restore)

      (global-set-key [?\S-\040]  'bc-set)
      (global-set-key "\M-j"      'bc-previous)
      (global-set-key "\S-\M-j"   'bc-next)
      (global-set-key [M-up]      'bc-local-previous)
      (global-set-key [M-down]    'bc-local-next)
      (global-set-key "\C-cj"     'bc-goto-current)
      (global-set-key "\C-x\M-j"  'bc-list)
      (global-set-key [C-f2]      'bc-set)
      (global-set-key [f2]        'bc-previous)
      (global-set-key [S-f2]      'bc-next)
      (global-set-key [M-f2]      'bc-list)

      (global-set-key [(shift space)] 'bc-set)
      (global-set-key [(meta j)] 'bc-previous)
      (global-set-key [(shift meta j)] 'bc-next)
      (global-set-key [(meta up)] 'bc-local-previous)
      (global-set-key [(meta down)] 'bc-local-next)
      (global-set-key [(control c)(j)]     'bc-goto-current)
      (global-set-key [(control x)(meta j)]  'bc-list)

      (global-set-key [(control F2)]      'bc-set)
      (global-set-key [(f2)]        'bc-previous)
      (global-set-key [(shift f2)]      'bc-next)
      (global-set-key [(meta f2)]      'bc-list)

      )

    (defun bc-dbgtest ()
      (interactive)
      ;(message (buffer-file-name))
      ;(message (buffer-name))
      (message (symbol-name major-mode))
      )
)

;;
