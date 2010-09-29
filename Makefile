EMACS = emacs

VERSION = 1.1.4
PREFIX = /usr/local
ELS = breadcrumb.el
ELCS = $(ELS:.el=.elc)

AUTOLOADS = breadcrumb-site-file.el

all: $(ELCS) $(AUTOLOADS)

%.elc: %.el
	@echo "[C] $<"
	@$(EMACS) --batch \
                  --eval '(setq load-path (cons (expand-file-name ".") load-path))' \
                  -f batch-byte-compile $<

$(AUTOLOADS) : $(ELS)
	@[ -f $@ ] || echo '' >$@
	@$(EMACS) --batch \
                  --eval '(setq generated-autoload-file (expand-file-name "$@"))' \
                  -f batch-update-autoloads "."
	@touch $@

clean:
	rm -fr $(ELCS)
	rm -fr $(AUTOLOADS)
