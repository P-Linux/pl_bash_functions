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
	cp -rf . $(DESTDIR)$(LIBDIR)/$(PKG_DIR)
	rm -rf	 $(DESTDIR)$(LIBDIR)/$(PKG_DIR)/Makefile

clean:
	rm -f main_conf.sh

# End of file
