#import <Preferences/PSViewController.h>
#import <Preferences/PSSpecifier.h>
#import <objc/runtime.h>
#include <dlfcn.h>

#define isIOS4 ([[[UIDevice currentDevice] systemVersion] hasPrefix:@"4"])
#define isIOS5 ([[[UIDevice currentDevice] systemVersion] hasPrefix:@"5"])
#define isWildcats ([[UIDevice currentDevice] respondsToSelector:@selector(isWildcat)] && [[UIDevice currentDevice] isWildcat])
#define PLIST @"/System/Library/PreferenceBundles/iNoRotatePreferences.bundle/settings.plist"
#define iNoRotate_PLIST @"/var/mobile/Library/Preferences/us.nakedproductions.inorotate.plist"

extern NSString * SBSCopyLocalizedApplicationNameForDisplayIdentifier(NSString *identifier);
extern NSString * SBSCopyIconImagePathForDisplayIdentifier(NSString *identifier);	
static NSData * (*SBSCopyIconImagePNGDataForDisplayIdentifier)(NSString *identifier) = NULL;

@interface UIKeyboard
@end

@interface UIModalView
@end

@interface PSViewController (iPad)
- (id)navigationController;
- (void)setSpecifier:(PSSpecifier *)spec;
- (void)viewWillDisappear;
- (void)viewWillAppear:(BOOL)animated;
@end

@interface UIKeyboard (iPad)
+ (void)initImplementationNow;
@end

@interface UIDevice (iPad)
- (BOOL)isWildcat;
@end

/****************************************************************************************************************/

@interface ALApplicationCell : UITableViewCell 
@end

@implementation ALApplicationCell
- (void)layoutSubviews {
    [super layoutSubviews];
    // Resize icon image
    CGSize size = self.bounds.size;
    self.imageView.frame = CGRectMake(4.0f, 4.0f, size.height - 8.0f, size.height - 8.0f);
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
}

@end

/****************************************************************************************************************/
/****************************************************************************************************************/

@interface iNoRotatePreferences : PSViewController <UITableViewDelegate, UITableViewDataSource> {
	UITableView			*tblView;
	NSMutableArray		*appStore;
	NSMutableArray		*system;
	NSMutableDictionary	*plistDict;
	UISwitch			*enableSwitch;
    UIActivityIndicatorView *actView;
	BOOL				loadApps;
}

- (NSString *) navigationTitle;
- (void)setNavigationTitle:(NSString *)navigationTitle;
- (void)loadFromSpecifier:(PSSpecifier *)specifier;
- (void) loadSystemApps;
@end

@implementation iNoRotatePreferences

#pragma mark -
#pragma mark == PSViewController Lifetime ==

- (id) initForContentSize:(CGSize)size {
	return [self init];
}

- (id)init {
	self = [super init];
	return self;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewWillRedisplay {
	[super viewWillRedisplay];
}

- (void)viewWillDisappear {
	[super viewWillDisappear];
}

- (void)viewWillBecomeVisible:(void *)source {
	if (source) {
		[self loadFromSpecifier:(PSSpecifier *)source];
	}
	[super viewWillBecomeVisible:source];
}

- (void)setNavigationTitle:(NSString *)navigationTitle {
	if ([self respondsToSelector:@selector(navigationItem)]) { [[self navigationItem] setTitle:navigationTitle]; }
}

- (id) view {
	return tblView;
}

#pragma mark -
#pragma mark == Private Methods ==

- (NSString *) navigationTitle {
	return @"iNoRotate";
}

- (void) loadApps:(BOOL)shouldLoad {
	[plistDict setObject:[NSNumber numberWithBool:shouldLoad] forKey:@"enabled"];
	[plistDict writeToFile:iNoRotate_PLIST atomically:YES];
	[tblView reloadData];
}

- (void) enableSwitch {
    loadApps = !loadApps;

	[plistDict setObject:[NSNumber numberWithBool:loadApps] forKey:@"enabled"];
	[plistDict writeToFile:iNoRotate_PLIST atomically:YES];
	[tblView reloadData];
}

- (void) loadSystemApps {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *systemAppPaths = [[NSMutableArray alloc] init];
    system = [[NSMutableArray alloc] init];
    
	for (NSString *systemAppPath in [fileManager contentsOfDirectoryAtPath:@"/Applications" error:nil]) {
		if ([systemAppPath hasSuffix:@".app"] && ![systemAppPath hasPrefix:@"."])
			[systemAppPaths addObject:[NSString stringWithFormat:@"/Applications/%@", systemAppPath]];
	}
    
    
	for (NSString *path in systemAppPaths) {
		NSBundle *bundle = [NSBundle bundleWithPath:path];
		if (bundle) {
			NSString *identifier = [bundle bundleIdentifier];
			if (isWildcats || [[[UIDevice currentDevice] model] isEqualToString:@"iPod touch"]) {
				if ([[bundle bundleIdentifier] isEqualToString:@"com.apple.mobileipod"]) {
					[system addObject:@"com.apple.mobileipod-AudioPlayer"];
					[system addObject:@"com.apple.mobileipod-VideoPlayer"];
					identifier = nil;
				} 
                else if ([[bundle bundleIdentifier] isEqualToString:@"com.apple.mobileslideshow"]) {
					[system addObject:@"com.apple.mobileslideshow-Photos"];
					identifier = nil;
				}
			} 
			else {
				if ([[bundle bundleIdentifier] isEqualToString:@"com.apple.mobileipod"]) {
					[system addObject:@"com.apple.mobileipod-MediaPlayer"];
					identifier = nil;
				} 
                else if ([[bundle bundleIdentifier] isEqualToString:@"com.apple.mobileslideshow"]) {
					[system addObject:@"com.apple.mobileslideshow-Photos"];
					[system addObject:@"com.apple.mobileslideshow-Camera"];
					identifier = nil;
				}
			}
			if (identifier && ![identifier hasPrefix:@"jp.ashikase.springjumps."] && ![identifier isEqualToString:@"com.apple.webapp"]) {
				[system addObject:identifier];
            }
		}
	}
	[systemAppPaths release];
}

- (void) loadAppStoreApps {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *appStoreAppPaths = [[NSMutableArray alloc] init];
    appStore = [[NSMutableArray alloc] init];
    
	for (NSString *path in [fileManager contentsOfDirectoryAtPath:@"/var/mobile/Applications" error:nil]) {
		for (NSString *subpath in [fileManager contentsOfDirectoryAtPath:[NSString stringWithFormat:@"/var/mobile/Applications/%@", path] error:nil]) {
			if ([subpath hasSuffix:@".app"]) {
				[appStoreAppPaths addObject:[NSString stringWithFormat:@"/var/mobile/Applications/%@/%@", path, subpath]];
            }
		}
	}
    
    
	for (NSString *path in appStoreAppPaths) {
		NSBundle *bundle = [NSBundle bundleWithPath:path];
		if (bundle) {
			NSString *identifier = [bundle bundleIdentifier];
			if (identifier && ![identifier hasPrefix:@"jp.ashikase.springjumps."] && ![identifier isEqualToString:@"com.apple.webapp"]) {
				[appStore addObject:identifier];
            }
		}
	}
    [appStoreAppPaths release];
}

- (void) showActivityView:(BOOL)show {
    if (show) {
        actView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [actView.layer setValue:[NSNumber numberWithFloat:0.8f] forKeyPath:@"transform.scale"];
        actView.frame = CGRectMake(0.0f, 0.0f, 32.0f, 32.0f);
        actView.center = CGPointMake(tblView.frame.size.width/2, tblView.frame.size.height/2);
        [tblView addSubview:actView];
        [actView startAnimating];
    }
    else {
        [actView stopAnimating];
        [actView release];
    }
}

#pragma mark -
#pragma mark == Specifiers ==

- (void)setSpecifier:(PSSpecifier *)specifier {
	[self loadFromSpecifier:specifier];
	[super setSpecifier:specifier];
}

- (void)loadFromSpecifier:(PSSpecifier *)specifier {
	[self setNavigationTitle:[self navigationTitle]];
	
	plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:iNoRotate_PLIST];
	if (plistDict == nil) { plistDict = [[NSMutableDictionary alloc] init]; }
    
	if ([plistDict objectForKey:@"enabled"] ? [[plistDict objectForKey:@"enabled"] boolValue] : NO) loadApps = YES;
	else loadApps = NO; 
	
	SBSCopyIconImagePNGDataForDisplayIdentifier = dlsym(RTLD_DEFAULT, "SBSCopyIconImagePNGDataForDisplayIdentifier");
    
	tblView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width,[[UIScreen mainScreen] bounds].size.height - 65.0f) style:UITableViewStyleGrouped];
	[tblView setDataSource:self];
	[tblView setDelegate:self];
    
    [self showActivityView:YES];
	[self loadSystemApps];
    [self loadAppStoreApps];
    [self showActivityView:NO];
}			 

#pragma mark -
#pragma mark == Pop Controllers ==

- (BOOL)popController {
	return [super popController];
}

-(BOOL)popControllerWithAnimation:(BOOL)animation {
	return [super popControllerWithAnimation:animation];
}

- (void)popNavigationItemWithAnimation:(BOOL)animated {
	[super popNavigationItemWithAnimation:animated];
}

-(void)navigationBarButtonClicked:(int)clicked {
	[super navigationBarButtonClicked:clicked];
}

- (void)popNavigationItem {
	[super popNavigationItem];
}


#pragma mark -
#pragma mark == TableView ==

- (int)numberOfSectionsInTableView:(UITableView *)tableView {
	return 3;
}

- (id)tableView:(UITableView *)tableView titleForHeaderInSection:(int)section {
	switch (section) {
		case 0:
			return @"Enable";
			break;
		case 1:
			if (loadApps && [system count] > 0) return @"System Apps";
			break;
		case 2:
			if (loadApps && [appStore count] > 0) return @"AppStore Apps";
			break;
		default:
			break;
	}
	return nil;
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(int)section {
	switch (section) {
		case 0:
			return 1;
			break;
		case 1:
			if (loadApps) return [system count];
			break;
		case 2:
			if (loadApps) return [appStore count];
			break;
		default:
			break;
	}
	return 0;
}

- (id)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {	
	NSString *reuseIdentifier = [NSString stringWithFormat:@"ApplicationCell%d%d", indexPath.section, indexPath.row];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if (cell == nil) {
		cell = [[[ALApplicationCell alloc] initWithFrame:CGRectZero reuseIdentifier:reuseIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	NSString *identifier;
	NSString *displayName;
	id appIsEnabled = nil;
	UIImage *icon = nil;
	switch (indexPath.section) {
		case 0:
			if (indexPath.row == 0) {
				[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
				cell.textLabel.textAlignment		= UITextAlignmentLeft;
				cell.textLabel.text = @"Enable:";
				
				enableSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
				[enableSwitch addTarget:self action:@selector(enableSwitch) forControlEvents:UIControlEventValueChanged];
				cell.accessoryView = enableSwitch;
				id switchEnabled = [plistDict objectForKey:@"enabled"];
				if (switchEnabled ? [switchEnabled boolValue] : NO) {
					[enableSwitch setOn:YES];
				}
			}
			break;
		case 1:
			cell.accessoryView = nil;
			
			identifier = [system objectAtIndex:indexPath.row];
			appIsEnabled = [plistDict objectForKey:identifier];
			if (appIsEnabled ? [appIsEnabled boolValue] : NO) { [cell setAccessoryType:UITableViewCellAccessoryCheckmark]; }
			else { [cell setAccessoryType:UITableViewCellAccessoryNone]; }
			displayName = SBSCopyLocalizedApplicationNameForDisplayIdentifier(identifier);
			cell.textLabel.text = displayName;
			[displayName release];
			
			if (isIOS4 || isIOS5) {
				// iOS >= 4.0
				if (SBSCopyIconImagePNGDataForDisplayIdentifier != NULL) {
					NSData *data = (*SBSCopyIconImagePNGDataForDisplayIdentifier)(identifier);
					if (data != nil) {
						icon = [UIImage imageWithData:data];
						[data release];
					}
				}
			} 
			else {
				// iOS < 4.0
				NSString *iconPath = SBSCopyIconImagePathForDisplayIdentifier(identifier);
				if (iconPath != nil) {
					icon = [UIImage imageWithContentsOfFile:iconPath];
					[iconPath release];
				}
			}
			cell.imageView.image = icon;
			break;
		case 2:
			cell.accessoryView = nil;
			identifier = [appStore objectAtIndex:indexPath.row];
			appIsEnabled = [plistDict objectForKey:identifier];
			if (appIsEnabled ? [appIsEnabled boolValue] : NO) { [cell setAccessoryType:UITableViewCellAccessoryCheckmark]; }
			else { [cell setAccessoryType:UITableViewCellAccessoryNone]; }
			displayName = SBSCopyLocalizedApplicationNameForDisplayIdentifier(identifier);
			displayName = SBSCopyLocalizedApplicationNameForDisplayIdentifier(identifier);
			cell.textLabel.text = displayName;
			[displayName release];
			
			if (isIOS4 || isIOS5) {
				// iOS >= 4.0
				if (SBSCopyIconImagePNGDataForDisplayIdentifier != NULL) {
					NSData *data = (*SBSCopyIconImagePNGDataForDisplayIdentifier)(identifier);
					if (data != nil) {
						icon = [UIImage imageWithData:data];
						[data release];
					}
				}
			} 
			else {
				// iOS < 4.0
				NSString *iconPath = SBSCopyIconImagePathForDisplayIdentifier(identifier);
				if (iconPath != nil) {
					icon = [UIImage imageWithContentsOfFile:iconPath];
					[iconPath release];
				}
			}
			cell.imageView.image = icon;
			break;
		default:
			cell.accessoryView = nil;
			cell.textLabel.text = @"Faulty Cell";
			[cell imageView].image = nil;
			break;
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	NSString *identifier = nil;
	//NSString *displayName = nil;
	id appIsEnabled = nil;
	switch (indexPath.section) {
		case 0:
			break;
		case 1:
			identifier = [system objectAtIndex:indexPath.row];
			//displayName = SBSCopyLocalizedApplicationNameForDisplayIdentifier(identifier);
			appIsEnabled = [plistDict objectForKey:identifier];
			if (appIsEnabled ? ![appIsEnabled boolValue] : YES) { 
				[plistDict setObject:[NSNumber numberWithBool:YES] forKey:identifier]; 
				[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
			}
			else { 
				[plistDict setObject:[NSNumber numberWithBool:NO] forKey:identifier]; 
				[cell setAccessoryType:UITableViewCellAccessoryNone];
			}
			[plistDict writeToFile:iNoRotate_PLIST atomically:YES];
			break;
		case 2:
			identifier = [appStore objectAtIndex:indexPath.row];
			appIsEnabled = [plistDict objectForKey:identifier];
			if (appIsEnabled ? ![appIsEnabled boolValue] : YES) { 
				[plistDict setObject:[NSNumber numberWithBool:YES] forKey:identifier]; 
				[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
			}
			else { 
				[plistDict setObject:[NSNumber numberWithBool:NO] forKey:identifier]; 
				[cell setAccessoryType:UITableViewCellAccessoryNone];
			}
			[plistDict writeToFile:iNoRotate_PLIST atomically:YES];
			//displayName = SBSCopyLocalizedApplicationNameForDisplayIdentifier(identifier);
			break;
		default:
			break;
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    CFNotificationCenterPostNotificationWithOptions(CFNotificationCenterGetDarwinNotifyCenter(),
													CFSTR("us.nakedproductions.inorotate.update"),  
													NULL, 
													NULL,
													kCFNotificationDeliverImmediately);
}

#pragma mark -
#pragma mark == Memory ==

- (void) dealloc {
	[system release];
	[appStore release];
	[tblView release];
	[plistDict release];
	[enableSwitch release];
	[super dealloc];
}

@end