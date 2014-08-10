#import <CoreFoundation/CoreFoundation.h>
#import <Preferences/Preferences.h>
#import <libapplist/AppList.h>
#import <substrate.h>
#import "AppSettingsListController.h"

@interface iNoRotateSettingsListController: PSListController 
@property (nonatomic) ALApplicationList *applicationList;
@property (nonatomic) NSDictionary *userApplications;
@property (nonatomic) NSDictionary *systemApplications;
@end

@implementation iNoRotateSettingsListController
@synthesize applicationList,userApplications,systemApplications;
//from applist

-(NSArray *)hiddenDisplayIdentifiers {
	return [[NSArray alloc] initWithObjects:
		                            @"com.apple.AdSheet",
		                            @"com.apple.AdSheetPhone",
		                            @"com.apple.AdSheetPad",
		                            @"com.apple.DataActivation",
		                            @"com.apple.DemoApp",
		                            @"com.apple.fieldtest",
		                            @"com.apple.iosdiagnostics",
		                            @"com.apple.iphoneos.iPodOut",
		                            @"com.apple.TrustMe",
		                            @"com.apple.WebSheet",
		                            @"com.apple.springboard",
                                    @"com.apple.purplebuddy",
                                    @"com.apple.datadetectors.DDActionsService",
                                    @"com.apple.FacebookAccountMigrationDialog",
                                    @"com.apple.iad.iAdOptOut",
                                    @"com.apple.ios.StoreKitUIService",
                                    @"com.apple.TextInput.kbd",
                                    @"com.apple.MailCompositionService",
                                    @"com.apple.mobilesms.compose",
                                    @"com.apple.quicklook.quicklookd",
                                    @"com.apple.ShoeboxUIService",
                                    @"com.apple.social.remoteui.SocialUIService",
                                    @"com.apple.WebViewService",
                                    @"com.apple.gamecenter.GameCenterUIService",
									@"com.apple.appleaccount.AACredentialRecoveryDialog",
									@"com.apple.CompassCalibrationViewService",
									@"com.apple.WebContentFilter.remoteUI.WebContentAnalysisUI",
									@"com.apple.PassbookUIService",
									@"com.apple.uikit.PrintStatus",
									@"com.apple.Copilot",
									@"com.apple.MusicUIService",
									@"com.apple.AccountAuthenticationDialog",
									@"com.apple.MobileReplayer",
									@"com.apple.SiriViewService",
		                            nil];
}

-(void)setTweakEnabled:(NSNumber *)value forSpecifier:(PSSpecifier *)spec {

	[self setPreferenceValue:value specifier:spec];
	[[NSUserDefaults standardUserDefaults] synchronize];

	if (value == kCFBooleanTrue) {
		[self insertContiguousSpecifiers:[self applicationSpecifiers] afterSpecifierID:@"excludesb" animated:TRUE];
	} else {
		[self removeContiguousSpecifiers:@[[self specifierForID:@"userapps"]] animated:TRUE];
		[self removeContiguousSpecifiers:@[[self specifierForID:@"systemapps"]] animated:TRUE];
	}
}

-(NSNumber *)getTweakEnabledForSpecifier:(PSSpecifier *)spec {
	return [self readPreferenceValue:spec];
}

-(NSString *)getAppInfoForIdentifier:(NSString *)identifer withKey:(NSString *)key {
    NSDictionary *infoPlist = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Info.plist",[self.applicationList valueForKeyPath:@"bundle.bundlePath" forDisplayIdentifier:identifer]]];
    return [infoPlist objectForKey:key];
}


-(void)loadSpecifiersForAppDictionary:(NSDictionary *)apps intoArray:(NSMutableArray *)inArray {

	for (NSString *key in [apps allKeys]) {
		if ([[self hiddenDisplayIdentifiers] containsObject:key]) {
			continue;
		}
		PSSpecifier *appSpecifier = [PSSpecifier preferenceSpecifierNamed:[apps objectForKey:key] target:self set:nil get:nil detail:[AppSettingsListController class] cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:nil];
		[appSpecifier setIdentifier:key];
		[appSpecifier setProperty:[self getAppInfoForIdentifier:key withKey:@"CFBundleVersion"] forKey:@"kAppVersion"];
		[appSpecifier setProperty:[self.applicationList valueForKeyPath:@"bundle.bundlePath" forDisplayIdentifier:key] forKey:@"kAppPath"];
		[appSpecifier setProperty:@(YES) forKey:@"enabled"];
		[appSpecifier setProperty:[self.applicationList iconOfSize:ALApplicationIconSizeSmall forDisplayIdentifier:key] forKey:@"iconImage"];
		[appSpecifier setProperty:[self.applicationList iconOfSize:ALApplicationIconSizeLarge forDisplayIdentifier:key] forKey:@"bigIconImage"];
		[inArray addObject:appSpecifier];

	}
}

-(NSArray *)applicationSpecifiers {

	NSMutableArray *applicationSpecs = [NSMutableArray array];

	PSSpecifier *userAppsSpec = [PSSpecifier groupSpecifierWithName:@"User Applications"];
	[userAppsSpec setIdentifier:@"userapps"];
	[applicationSpecs addObject:userAppsSpec];

	[self loadSpecifiersForAppDictionary:self.userApplications intoArray:applicationSpecs];

	PSSpecifier *systemAppsSpec = [PSSpecifier groupSpecifierWithName:@"System Applications"];
	[systemAppsSpec setIdentifier:@"systemapps"];
	[applicationSpecs addObject:systemAppsSpec];

	[self loadSpecifiersForAppDictionary:self.systemApplications intoArray:applicationSpecs];

	return (NSArray *)[applicationSpecs copy];
}

- (id)specifiers {

	if(_specifiers == nil) {

		NSMutableArray *specs = [NSMutableArray array];

		self.applicationList = [ALApplicationList sharedApplicationList];
		self.userApplications = [self.applicationList applicationsFilteredUsingPredicate:[NSPredicate predicateWithFormat:@"isSystemApplication=FALSE"]];
		self.systemApplications = [self.applicationList applicationsFilteredUsingPredicate:[NSPredicate predicateWithFormat:@"isSystemApplication=TRUE"]];

		PSSpecifier *header = [PSSpecifier groupSpecifierWithName:@"iNoRotate by EvilPenguin and sharedRoutine"];
		[specs addObject:header];

		PSSpecifier *enableSpec = [PSSpecifier preferenceSpecifierNamed:@"Enabled" target:self set:@selector(setTweakEnabled:forSpecifier:) get:@selector(getTweakEnabledForSpecifier:) detail:nil cell:[PSTableCell cellTypeFromString:@"PSSwitchCell"] edit:nil];
		[enableSpec setProperty:@(YES) forKey:@"default"];
		[enableSpec setProperty:@"com.sharedroutine.inorotate" forKey:@"defaults"];
		[enableSpec setProperty:@"kEnabled" forKey:@"key"];
		[enableSpec setIdentifier:@"enable"];
		[enableSpec setProperty:@"com.sharedroutine.inorotate.settingschanged" forKey:@"PostNotification"];
		[specs addObject:enableSpec];

		PSSpecifier *excludeSB = [PSSpecifier preferenceSpecifierNamed:@"Exclude SpringBoard" target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:nil cell:[PSTableCell cellTypeFromString:@"PSSwitchCell"] edit:nil];
		[excludeSB setProperty:@(YES) forKey:@"default"];
		[excludeSB setProperty:@"com.sharedroutine.inorotate" forKey:@"defaults"];
		[excludeSB setProperty:@"kExcludeSpringBoard" forKey:@"key"];
		[excludeSB setIdentifier:@"excludesb"];
		[excludeSB setProperty:@"com.sharedroutine.inorotate.settingschanged" forKey:@"PostNotification"];
		[specs addObject:excludeSB];

		if ([self readPreferenceValue:enableSpec] == kCFBooleanTrue) {
			[specs addObjectsFromArray:[self applicationSpecifiers]];
		}
		
		_specifiers = (NSArray *)[specs copy];
	}

	return _specifiers;
}
@end

// vim:ft=objc
