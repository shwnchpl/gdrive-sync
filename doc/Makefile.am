include $(top_srcdir)/local.mk

man_MANS = gdrive-sync.1
sysconf_DATA = gdsconfig

EXTRA_DIST = \
	gdrive-sync.1.pod \
	sample.gdsconfig

MOSTLYCLEANFILES = $(man_MANS) $(man_MANS:.1=.pod) $(sysconf_DATA)

%.1: %.1.pod Makefile
	$(process_ac_vars) < $< > $*.pod
	$(POD2MAN) \
		--name="$(shell $(AWK) '{print toupper($$0)}' <<< $(PACKAGE_NAME))" \
		--center='$(PACKAGE_NAME)' \
		--release='$(PACKAGE_STRING)' \
		--section=1 $*.pod > $@

%: sample.% Makefile
	$(process_ac_vars) < $< > $@
