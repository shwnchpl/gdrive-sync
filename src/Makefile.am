bin_SCRIPTS = gdrive-sync

EXTRA_DIST = \
	gdrive-sync.bash

%: %.bash Makefile
	cp $< $@
	chmod go-w,+x $@
