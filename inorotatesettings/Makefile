include theos/makefiles/common.mk

BUNDLE_NAME = iNoRotateSettings
iNoRotateSettings_FILES = iNoRotateSettings.mm AppSettingsListController.mm
iNoRotateSettings_INSTALL_PATH = /Library/PreferenceBundles
iNoRotateSettings_FRAMEWORKS = UIKit MobileCoreServices
iNoRotateSettings_PRIVATE_FRAMEWORKS = Preferences
iNoRotateSettings_CFLAGS = -fobjc-arc -w
iNoRotateSettings_LIBRARIES = applist

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/iNoRotateSettings.plist$(ECHO_END)
