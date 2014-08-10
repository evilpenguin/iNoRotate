#import <UIKit/UIKit.h>

#define GET_BOOL(prefs,key,def) [prefs objectForKey:@(key)] ? [[prefs objectForKey:@(key)] boolValue] : def;
#define PLIST_PATH @"/var/mobile/Library/Preferences/com.sharedroutine.inorotate.plist"

NSDictionary *settings = nil;
BOOL excludeSpringBoard, enabled;
NSDictionary *appSettings = nil;

extern "C" {

	typedef struct __GSEvent {
	//GSEventRecord record;
	} GSEvent;
	typedef struct __GSEvent* GSEventRef;

	typedef enum __GSEventType {
		kGSEventDeviceOrientationChanged = 50,
	} GSEventType;

	int GSEventDeviceOrientation(GSEventRef event);

	GSEventType GSEventGetType(GSEventRef event);	

}

@interface UIApplication(iNoRoate)
-(NSString *)displayIdentifier;
@end

%hook UIApplication

- (void)handleEvent:(GSEventRef)gsEvent withNewEvent:(UIEvent *)newEvent { 

	if (!enabled) { %orig; return;}

	if (gsEvent && GSEventGetType(gsEvent) == kGSEventDeviceOrientationChanged) {
			if (excludeSpringBoard && [[self displayIdentifier] isEqualToString:@"com.apple.springboard"]) {
				%orig;
				return;
			}

			appSettings = settings[[self displayIdentifier]] ?: [NSDictionary dictionary];
			BOOL anyDirection = GET_BOOL(appSettings,"kAnyDirection",TRUE);
			if (anyDirection) {
				%orig;
				return;
			}

			int wantsOrientation = GSEventDeviceOrientation(gsEvent);

			NSArray *allowedOrientations = [appSettings objectForKey:@"kAllowedOrientations"] ?: @[];
			if ([allowedOrientations containsObject:@(wantsOrientation)]) {
				%orig;
				return;
			} else {
				return;
			}
	} 

	%orig;
}

%end

void settingsUpdated(CFNotificationCenterRef center,
                           void * observer,
                           CFStringRef name,
                           const void * object,
                           CFDictionaryRef userInfo) {

	settings = nil;
	settings = [NSDictionary dictionaryWithContentsOfFile:PLIST_PATH];
	excludeSpringBoard = GET_BOOL(settings,"kExcludeSpringBoard",TRUE);
	enabled = GET_BOOL(settings,"kEnabled",TRUE);
}

%ctor {

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, settingsUpdated, CFSTR("com.sharedroutine.inorotate.settingschanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

	settings = [NSDictionary dictionaryWithContentsOfFile:PLIST_PATH];
	excludeSpringBoard = GET_BOOL(settings,"kExcludeSpringBoard",TRUE);
	enabled = GET_BOOL(settings,"kEnabled",TRUE);
	
	if (enabled) {
		%init;
	}
}