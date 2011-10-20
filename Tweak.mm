/*
 * Project: iNoRotate
 * Creator: EvilPenguin|
 * Version: 2.1-1
 */

#include <GraphicsServices/GraphicsServices.h>

#define iNoRotate_PLIST @"/var/mobile/Library/Preferences/us.nakedproductions.inorotate.plist"
#define listenToNotification$withCallBack(notification, callback); CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)&callback, CFSTR(notification), NULL, CFNotificationSuspensionBehaviorHold);

@interface SBUIController
	- (void) finishedUnscattering;
@end

@interface SBOrientationLockManager
	+ (id) sharedInstance;
	- (void)lock:(int)lock;
	- (void)unlock;
	- (BOOL)isLocked;
	- (int)lockOrientation;
	- (void)setLockOverride:(int)override orientation:(int)orientation;
	- (int)lockOverride;
	- (void)updateLockOverrideForCurrentDeviceOrientation;
@end

@interface UIApplication () 
	- (id)displayIdentifier;
	- (void) handleEvent:(GSEventRef)gsEvent withNewEvent:(UIEvent *)newEvent;
@end

#pragma mark -
#pragma mark == Static Public Methods ==

static NSMutableDictionary *plistDict = nil;
static void loadSettings() {
    NSLog(@"iNoRotate: I stop your apps from rotating.");
	if (plistDict) {
		[plistDict release];
		plistDict = nil;
	}
	plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:iNoRotate_PLIST];
    if (plistDict == nil) { plistDict = [[NSMutableDictionary alloc] init]; }
}


static void welcomeLoad() {
	if ([[plistDict objectForKey:@"tutorial"] isEqualToString:@"loaded"]) { return; }
	else {
		UIAlertView *tutorialAlert = [[UIAlertView alloc] initWithTitle:@"Welcome To iNoRotate!" 
																message:@"To enable or disable anything, go to settings and choose iNoRotate :)" 
															   delegate:nil 
													  cancelButtonTitle:@"Okay" 
													  otherButtonTitles:nil];
		[tutorialAlert show];
		[tutorialAlert release];
        
		[plistDict setValue:@"loaded" forKey:@"tutorial"];
		[plistDict writeToFile:iNoRotate_PLIST atomically:YES];
	}
}

#pragma mark -
#pragma mark == SBUIController ==

%hook SBUIController
- (void) finishedUnscattering {
    %orig;
	welcomeLoad();
}
%end

#pragma mark -
#pragma mark == UIApplication ==

%hook UIApplication
- (void) handleEvent:(GSEventRef)gsEvent withNewEvent:(UIEvent *)newEvent { 
	if ([plistDict objectForKey:@"enabled"]  ? [[plistDict objectForKey:@"enabled"] boolValue] : NO) {
		if ([plistDict objectForKey:[self displayIdentifier]] ? [[plistDict objectForKey:[self displayIdentifier]] boolValue] : NO) { 
			if (gsEvent) { 
                if (GSEventGetType(gsEvent) == 50) return; 
            }
		}
	}
	%orig;
}
%end

%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	%init;
	listenToNotification$withCallBack("us.nakedproductions.inorotate.update", loadSettings);
	loadSettings();
	[pool drain];
}