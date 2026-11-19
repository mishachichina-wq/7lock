INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SixLS
SixLS_FILES = $(wildcard *.swift) $(wildcard *.m) Tweak.x
SixLS_CFLAGS = -fobjc-arc -I./Headers
SixLS_SWIFTFLAGS += -DTWEAK

# UserNotificationsKit has headers but no linkable framework in this SDK.
# Defer resolution of its private Objective-C class symbol to runtime.
# Experimental: the class must be exported by a framework loaded on device.
SixLS_LDFLAGS += -Wl,-undefined,dynamic_lookup
include $(THEOS_MAKE_PATH)/tweak.mk
