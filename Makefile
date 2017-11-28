all: gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly
	@echo "Done"

BLDROOT=$(PWD)
STAGING=$(BLDROOT)/staging
OUTPUT=$(BLDROOT)/output

MKDIRS+=$(STAGING)
MKDIRS+=$(OUTPUT)

DEB_PKGS+=autoconf autopoint bison flex libtool
DEB_PKGS+=libglib2.0-dev

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
$(1)_PKG=$(BLDROOT)/pkg/$(1)

SOURCES+=$$($(1)_SRC)

MKDIRS+=$$($(1)_BLD)
MKDIRS+=$$($(1)_PKG)

$$($(1)_SRC):
	git clone $(2) --depth 1 $$@

$$($(1)_SRC)/configure: | $$($(1)_SRC) $$($(1)_BLD)
	cd $$($(1)_SRC) && ./autogen.sh \
		$$($(1)_AUTOGEN_OPTS) && \
		$$(MAKE) distclean 	## Workaround

$(1)-configure $$($(1)_BLD)/Makefile: $$($(1)_SRC)/configure
	cd $$($(1)_BLD) && \
		PKG_CONFIG_PATH=$(STAGING)/usr/lib/pkgconfig \
		$$($(1)_SRC)/configure \
			--prefix=/usr \
			$$($(1)_CONFIGURE_OPTS)

$(1)-configure-help: $$($(1)_SRC)/configure
	$$($(1)_SRC)/configure --help


$(1)-install: $$($(1)_BLD)/Makefile
	cd $$($(1)_BLD) && \
		$$(MAKE) install DESTDIR=$$($(1)_INSTALL)

$(1)-install-staging: $(1)_INSTALL=$(STAGING)
$(1)-install-staging: $(STAGING) $(1)-install

$(1)-package: $(1)_INSTALL=$$($(1)_PKG)
$(1)-package: $$($(1)_PKG) $(OUTPUT) $(1)-install
	@echo Make a package now
	cd $$($(1)_PKG) && \
		tar czf $$(OUTPUT)/$(1).tgz .

$(1)-build: $$($(1)_BLD)/Makefile
	cd $$($(1)_BLD) && \
		$$(MAKE) $$(J)

$(1): $(1)-build $(1)-install-staging

endef

GSTREAMER_COMMON_OPTS:=--disable-gtk-doc --prefix=/usr

######################################################################
### gstreamer

gstreamer_CONFIGURE_OPTS+=$(GSTREAMER_COMMON_OPTS)
gstreamer_AUTOGEN_OPTS+=$(GSTREAMER_COMMON_OPTS)
$(eval $(call autotools-git,gstreamer,git://anongit.freedesktop.org/gstreamer/gstreamer))

######################################################################
### gst-plugins-base

gst-plugins-base_CONFIGURE_OPTS+=$(GSTREAMER_COMMON_OPTS)
gst-plugins-base_AUTOGEN_OPTS+=$(GSTREAMER_COMMON_OPTS)
$(eval $(call autotools-git,gst-plugins-base,git://anongit.freedesktop.org/gstreamer/gst-plugins-base))

######################################################################
### gst-plugins-good

gst-plugins-good_CONFIGURE_OPTS+=$(GSTREAMER_COMMON_OPTS)
gst-plugins-good_AUTOGEN_OPTS+=$(GSTREAMER_COMMON_OPTS)
$(eval $(call autotools-git,gst-plugins-good,git://anongit.freedesktop.org/gstreamer/gst-plugins-good))

######################################################################
### gst-plugins-bad

gst-plugins-bad_CONFIGURE_OPTS+=$(GSTREAMER_COMMON_OPTS) --enable-kms
gst-plugins-bad_AUTOGEN_OPTS+=$(GSTREAMER_COMMON_OPTS) --enable-kms
$(eval $(call autotools-git,gst-plugins-bad,git://anongit.freedesktop.org/gstreamer/gst-plugins-bad))

######################################################################
### gst-plugins-ugly

gst-plugins-ugly_CONFIGURE_OPTS+=$(GSTREAMER_COMMON_OPTS)
gst-plugins-ugly_AUTOGEN_OPTS+=$(GSTREAMER_COMMON_OPTS)
$(eval $(call autotools-git,gst-plugins-ugly,git://anongit.freedesktop.org/gstreamer/gst-plugins-ugly))

######################################################################
### Helpers

$(MKDIRS):
	@echo " [MKDIR] " $@
	@mkdir -p $@

sources: $(SOURCES)
