export THEOS_DEVICE_IP = localhost
export THEOS_DEVICE_PORT = 2222

TWEAK_NAME = iNoRotate
iNoRotate_FILES = Tweak.xm
iNoRotate_FRAMEWORKS = UIKit
iNoRotate_PRIVATE_FRAMEWORKS = GraphicsServices

BUNDLE_NAME = iNoRotatePreferences
iNoRotatePreferences_OBJC_FILES = iNoRotatePreferences.m
iNoRotatePreferences_FRAMEWORKS = UIKit Foundation CoreFoundation CoreGraphics GraphicsServices
iNoRotatePreferences_PRIVATE_FRAMEWORKS = SpringBoardServices Preferences
iNoRotatePreferences_INSTALL_PATH = /System/Library/PreferenceBundles

include theos/makefiles/common.mk
include theos/makefiles//tweak.mk
include theos/makefiles//bundle.mk