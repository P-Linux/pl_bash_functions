include Makefile.inc

.PHONY: all help install generate clean

all: help

help:
	@echo 'USAGE: `make [option] <target>` where <target> is one of'
	@echo
	@echo '  help              show the help information'
	@echo '  generate          generate final files from `filename.in`'
	@echo '  clean             clean'
	@echo '  install           re-build and install the package'
	@echo

install:
	rm -rf	 $(DESTDIR)$(LIBDIR)/$(PKG_DIR)
	install -D -m0755 LICENSE.md $(DESTDIR)$(LIBDIR)/$(PKG_DIR)/LICENSE.md
	install -D -m0755 RELEASE-NOTES.md $(DESTDIR)$(LIBDIR)/$(PKG_DIR)/RELEASE-NOTES.md
	install -D -m0755 README.md $(DESTDIR)$(LIBDIR)/$(PKG_DIR)/README.md
	$(MAKE) -C $(DIRSCRIPTS) install
	$(MAKE) -C $(DIRTESTS) install

generate:
	$(MAKE) -C $(DIRSCRIPTS) generate

clean:
	$(MAKE) -C $(DIRSCRIPTS) clean
