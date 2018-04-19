include $(top_srcdir)/local.mk

bin_SCRIPTS = gdrive-sync

EXTRA_DIST = \
	gdrive-sync.bash

%: %.bash Makefile
	$(process_ac_vars) < $< > $@
	chmod go-w,+x $@
