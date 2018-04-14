
man_MANS = gdrive-sync.1

EXTRA_DIST = \
	gdrive-sync.1.pod

MOSTLYCLEANFILES = $(man_MANS)

%.1: %.1.pod Makefile
	$(POD2MAN) \
		--name='GDRIVE-SYNC' \
		--center='gdrive-sync' \
		--release='gdrive-sync 0.0.3' \
		--section=1 $*.1.pod > $@
