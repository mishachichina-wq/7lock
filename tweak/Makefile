INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SixLS
SixLS_FILES = $(wildcard *.swift) $(wildcard *.m) Tweak.x
SixLS_CFLAGS = -fobjc-arc -I./Headers
SixLS_SWIFTFLAGS += -DTWEAK

# Do not link UserNotificationsKit: the build SDK lacks its binary.
# NCNotificationRequest is weak-imported in our local header.
include $(THEOS_MAKE_PATH)/tweak.mk
