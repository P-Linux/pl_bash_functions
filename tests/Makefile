include ../Makefile.inc

.PHONY: all install

all:
	@echo -e '\n=== target <all> only set in the top level directory\n\n'

install:
	mkdir -p $(DESTDIR)$(LIBDIR)/$(PKG_DIR)/$(DIRTESTS)
	cp -rf . $(DESTDIR)$(LIBDIR)/$(PKG_DIR)/$(DIRTESTS)
	rm -rf	 $(DESTDIR)$(LIBDIR)/$(PKG_DIR)/$(DIRTESTS)/Makefile

# End of file
