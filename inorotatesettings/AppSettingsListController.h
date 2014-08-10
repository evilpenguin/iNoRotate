#import <Preferences/Preferences.h>
#include <substrate.h>
#import "LSApplicationWorkSpace.h"

@interface AppSettingsListController : PSListController
@property (nonatomic,readonly,copy) NSString *bundleIdentifier;
@property (nonatomic,readonly,copy) NSString *applicationName;
@property (nonatomic,readonly,copy) NSString *appPath;
@property (nonatomic,readonly,copy) NSString *appVersion;
@property (nonatomic,readonly) UIImage *appIcon;
@property (nonatomic,readonly) NSUserDefaults *userDefaults;
@end