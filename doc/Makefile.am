
man_MANS = gdrive-sync.1
sysconf_DATA = gdsconfig

EXTRA_DIST = \
	gdrive-sync.1.pod \
	sample.gdsconfig

MOSTLYCLEANFILES = $(man_MANS) $(sysconf_DATA)

%.1: %.1.pod Makefile
	$(POD2MAN) \
		--name='GDRIVE-SYNC' \
		--center='gdrive-sync' \
		--release='gdrive-sync 0.0.3' \
		--section=1 $*.1.pod > $@

%: sample.% Makefile
	cp $< $@
