include ../Makefile.inc

edit = sed -i \
	-e 's|@_VERSION[@]|$(VERSION)|g'


.PHONY: all generate install clean

all:
	@echo -e '\n=== target <all> only set in the top level directory\n\n'

generate:
	cp -f main_conf.in main_conf.sh
	$(edit) "main_conf.sh"

install: generate
	mkdir -p $(DESTDIR)$(LIBDIR)/$(PKG_DIR)/$(DIRSCRIPTS)
	cp -rf . $(DESTDIR)$(LIBDIR)/$(PKG_DIR)/$(DIRSCRIPTS)/
	rm -rf	 $(DESTDIR)$(LIBDIR)/$(PKG_DIR)/$(DIRSCRIPTS)/Makefile

clean:
	rm -f main_conf.sh

# End of file
