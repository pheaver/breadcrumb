VERSION=1.1.4
PREFIX=/usr/local
ELS=breadcrumb.el
ELCS=$(ELS:.el=.elc)

all: $(ELCS)

EMACS=emacs

%.elc: %.el
	@echo "[C] $<"
	@$(EMACS) --batch --eval "(add-to-list 'load-path \"$(CURDIR)\")" \
                          --eval '(byte-compile-file "$<")'

clean:
	rm -fr $(ELCS)
