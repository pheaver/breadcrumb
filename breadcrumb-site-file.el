
;;;### (autoloads (bc-list bc-clear bc-goto-current bc-local-next
;;;;;;  bc-local-previous bc-next bc-previous bc-set) "breadcrumb"
;;;;;;  "breadcrumb.el" (19630 22935))
;;; Generated autoloads from breadcrumb.el

(autoload 'bc-set "breadcrumb" "\
Set a bookmark at the current buffer and current position.

\(fn)" t nil)

(autoload 'bc-previous "breadcrumb" "\
Jump to the previous bookmark.

\(fn)" t nil)

(autoload 'bc-next "breadcrumb" "\
Jump to the next bookmark.

\(fn)" t nil)

(autoload 'bc-local-previous "breadcrumb" "\
Jump to the previous bookmark in the local buffer.

\(fn)" t nil)

(autoload 'bc-local-next "breadcrumb" "\
Jump to the next bookmark in the local buffer.

\(fn)" t nil)

(autoload 'bc-goto-current "breadcrumb" "\
Jump to the current bookmark.

\(fn)" t nil)

(autoload 'bc-clear "breadcrumb" "\
Clear all the breadcrumb bookmarks in the queue.

\(fn)" t nil)

(autoload 'bc-list "breadcrumb" "\
Display the breadcrumb bookmarks in the buffer `*Breadcrumb Bookmarks*' to
allow interactive management of them.  Argument OTHER-WINDOW-P means to select
other buffer in other window.

\(fn &optional OTHER-WINDOW-P)" t nil)

;;;***

;;;### (autoloads nil nil ("breadcrumb-test.el") (19630 22937 609000))

;;;***

