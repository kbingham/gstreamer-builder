all: gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly
	@echo "Done"

BLDROOT=$(PWD)

DEB_PKGS+=autopoint bison flex

deb:
	apt-get install -y $(DEB_PKGS)

NPROC=$(shell nproc)
ifneq ($(NPROC),)
J:=-j$(NPROC)
endif

######################################################################
### auto-tools make wrapper
# 1: Package Name/Prefix
# 2: Git URL to clone
#
# Usage:
#   $(eval $(call autotools-git,<pkg-name>,<git-url>))

define autotools-git

$(1)_SRC=$(BLDROOT)/src/$(1)
$(1)_BLD=$(BLDROOT)/bld/$(1)

SOURCES+=$$($(1)_SRC)
MKDIRS+=$$($(1)_BLD)

$$($(1)_SRC):
	git clone $(2) --depth 1 $$@

$$($(1)_SRC)/configure: | $$($(1)_SRC) $$($(1)_BLD)
	cd $$($(1)_SRC) && ./autogen.sh && \
		$$(MAKE) distclean 	## Workaround

$$($(1)_BLD)/Makefile: $$($(1)_SRC)/configure
	cd $$($(1)_BLD) && \
		$$($(1)_SRC)/configure \
			--prefix=/usr \
			$$($(1)_CONFIGURE_OPTS)

$(1): | $$($(1)_BLD)/Makefile
	cd $$($(1)_BLD) && \
		$$(MAKE) $$(J) && \
		$$(MAKE) install

endef

######################################################################
### gstreamer

gstreamer_CONFIGURE_OPTS+=--prefix=/usr

$(eval $(call autotools-git,gstreamer,git://anongit.freedesktop.org/gstreamer/gstreamer))

######################################################################
### gst-plugins-base

$(eval $(call autotools-git,gst-plugins-base,git://anongit.freedesktop.org/gstreamer/gst-plugins-base))

######################################################################
### gst-plugins-good

$(eval $(call autotools-git,gst-plugins-good,git://anongit.freedesktop.org/gstreamer/gst-plugins-good))

######################################################################
### gst-plugins-bad

$(eval $(call autotools-git,gst-plugins-bad,git://anongit.freedesktop.org/gstreamer/gst-plugins-bad))

######################################################################
### gst-plugins-ugly

$(eval $(call autotools-git,gst-plugins-ugly,git://anongit.freedesktop.org/gstreamer/gst-plugins-ugly))

######################################################################
### Helpers

$(MKDIRS):
	@echo " [MKDIR] " $@
	@mkdir -p $@

sources: $(SOURCES)

s:
	@echo "Sources: "
	@echo $(SOURCES) | xargs -n 1
	@echo "MkDirs:"
	@echo $(MKDIRS) | xargs -n 1

