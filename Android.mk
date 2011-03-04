LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

GSTREAMER_AGGREGATE_TOP := $(abspath $(LOCAL_PATH))

ifneq ($(SYSROOT),)
NDK_BUILD := true
else
NDK_BUILD := false
endif

ifeq ($(GLIB_TOP),)
GLIB_TOP := $(GSTREAMER_AGGREGATE_TOP)/glib
endif

ifeq ($(gstreamer_TOP),)
gstreamer_TOP := $(GSTREAMER_AGGREGATE_TOP)/gstreamer
endif

ifeq ($(GST_PLUGINS_BASE_TOP),)
GST_PLUGINS_BASE_TOP := $(GSTREAMER_AGGREGATE_TOP)/gst-plugins-base
endif

ifeq ($(GST_PLUGINS_GOOD_TOP),)
GST_PLUGINS_GOOD_TOP := $(GSTREAMER_AGGREGATE_TOP)/gst-plugins-good
endif

ifeq ($(GST_PLUGINS_BAD_TOP),)
GST_PLUGINS_BAD_TOP := $(GSTREAMER_AGGREGATE_TOP)/gst-plugins-bad
endif

ifeq ($(GNONLIN_TOP),)
GNONLIN_TOP := $(GSTREAMER_AGGREGATE_TOP)/gnonlin
endif

ifeq ($(GES_TOP),)
GES_TOP := $(GSTREAMER_AGGREGATE_TOP)/gst-editing-services
endif

CONFIGURE_CC := $(TARGET_CC)
CONFIGURE_INCLUDES :=
CONFIGURE_LDFLAGS := -lc -ldl

ifeq ($(NDK_BUILD),true)
CONFIGURE_CFLAGS := \
    -nostdlib -Bdynamic \
    -Wl,-dynamic-linker,/system/bin/linker \
    -Wl,--gc-sections \
    -Wl,-z,nocopyreloc \
    $(call host-path,\
        $(TARGET_CRTBEGIN_DYNAMIC_O) \
        $(PRIVATE_OBJECTS)) \
    $(call link-whole-archives,$(PRIVATE_WHOLE_STATIC_LIBRARIES))\
    $(call host-path,\
        $(PRIVATE_STATIC_LIBRARIES) \
        $(TARGET_LIBGCC) \
        $(PRIVATE_SHARED_LIBRARIES)) \
    $(PRIVATE_LDFLAGS) \
    $(PRIVATE_LDLIBS) \
    $(call host-path,\
        $(TARGET_CRTEND_O)) \
	$(CONFIGURE_INCLUDES)
CONFIGURE_LDFLAGS += -L$(SYSROOT)/usr/lib
CONFIGURE_INCLUDES += -I$(SYSROOT)/usr/include
CONFIGURE_CPP := $(TOOLCHAIN_PREFIX)cpp

else

CONFIGURE_CC := $(patsubst %,$(PWD)/%,$(TARGET_CC))
CONFIGURE_LDFLAGS += -L$(PWD)/$(TARGET_OUT_INTERMEDIATE_LIBRARIES)

CONFIGURE_CFLAGS := \
    -nostdlib -Bdynamic \
    -Wl,-dynamic-linker,/system/bin/linker \
    -Wl,--gc-sections \
    -Wl,-z,nocopyreloc
CONFIGURE_LDFLAGS += \
    $(PWD)/$(TARGET_CRTBEGIN_DYNAMIC_O) \
    $(call link-whole-archives,$(PRIVATE_WHOLE_STATIC_LIBRARIES))\
    $(PRIVATE_STATIC_LIBRARIES) \
    $(PWD)/$(TARGET_LIBGCC) \
    $(PRIVATE_SHARED_LIBRARIES) \
		$(PWD)/$(TARGET_CRTEND_O)


CONFIGURE_CPP := $(PWD)/$(TARGET_TOOLS_PREFIX)cpp

CONFIGURE_INCLUDES += \
		$(foreach incdir, $(realpath $(C_INCLUDES) $(TARGET_C_INCLUDES)), \
				-I$(incdir)) \
		-I$(abspath $(TOP)/external/zlib) \
		-I$(GSTREAMER_AGGREGATE_TOP)/libid3tag \
		-I$(GSTREAMER_AGGREGATE_TOP)/libmad
endif

CONFIGURE_CPPFLAGS := \
	$(CONFIGURE_INCLUDES)

CONFIGURE_PKG_CONFIG_LIBDIR := $(GLIB_TOP):$(gstreamer_TOP)/pkgconfig:$(GST_PLUGINS_BASE_TOP)/pkgconfig:$(GST_PLUGINS_GOOD_TOP)/pkgconfig:$(GST_PLUGINS_BAD_TOP)/pkgconfig

PKG_CONFIG := PKG_CONFIG_LIBDIR=$(CONFIGURE_PKG_CONFIG_LIBDIR) PKG_CONFIG_TOP_BUILD_DIR=$(abspath $(TOP)) pkg-config
GST_CFLAGS := \
	-DD_GNU_SOURCE					\
	-DGST_DISABLE_DEPRECATED			\
	-DHAVE_CONFIG_H					\
	-I$(gstreamer_TOP)				\
	$(shell $(PKG_CONFIG) gstreamer --cflags)

CONFIGURE := autogen.sh

.SECONDARYEXPANSION:
CONFIGURE_TARGETS :=

#only in this order for reference... this is optimal build order
include $(GSTREAMER_AGGREGATE_TOP)/glib/Android.mk
include $(GSTREAMER_AGGREGATE_TOP)/gstreamer/Android.mk
include $(GSTREAMER_AGGREGATE_TOP)/gst-plugins-base/Android.mk
include $(GSTREAMER_AGGREGATE_TOP)/gst-plugins-good/Android.mk
include $(GSTREAMER_AGGREGATE_TOP)/gnonlin/Android.mk
include $(GSTREAMER_AGGREGATE_TOP)/gst-editing-services/Android.mk
include $(GSTREAMER_AGGREGATE_TOP)/gst-openmax/Android.mk
include $(GSTREAMER_AGGREGATE_TOP)/gst-plugins-bad/Android.mk
include $(GSTREAMER_AGGREGATE_TOP)/gst-android/Android.mk
include $(GSTREAMER_AGGREGATE_TOP)/gst-plugins-android2/Android.mk
include $(GSTREAMER_AGGREGATE_TOP)/libmad/Android.mk
include $(GSTREAMER_AGGREGATE_TOP)/libid3tag/Android.mk
include $(GSTREAMER_AGGREGATE_TOP)/gst-plugins-ugly/Android.mk

TARGETS:
	@echo $(CONFIGURE_TARGETS)

#has a funny gstreamer_TOP of its own, fix that
#include $(GSTREAMER_AGGREGATE_TOP)/gst-android/Android.mk

.PHONY: gstreamer-aggregate-configure
gstreamer-aggregate-configure: $(TARGET_CRTBEGIN_DYNAMIC_O) $(TARGET_CRTEND_O) $(TARGET_OUT_SHARED_LIBRARIES)/libc.so $(TARGET_OUT_SHARED_LIBRARIES)/libz.so $(CONFIGURE_TARGETS)
