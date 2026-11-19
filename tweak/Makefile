
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SixLS

SixLS_FILES = $(wildcard *.swift) $(wildcard *.m) Tweak.x

SixLS_CFLAGS = -fobjc-arc -I./Headers

SixLS_SWIFTFLAGS += -DTWEAK

SixLS_FRAMEWORKS = UIKit Foundation QuartzCore
SixLS_PRIVATE_FRAMEWORKS = UserNotificationsKit

include $(THEOS_MAKE_PATH)/tweak.mk
