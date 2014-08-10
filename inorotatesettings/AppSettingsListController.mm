#import "AppSettingsListController.h"

#define IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

@interface SRTableCell : PSTableCell
@end

@implementation SRTableCell

-(id)initWithStyle:(int)style reuseIdentifier:(NSString *)identifier specifier:(PSSpecifier *)specifier {

	self = [super initWithStyle:style reuseIdentifier:identifier specifier:specifier];

	if (self) {
		if ([specifier.identifier isEqualToString:@"orientations"] || [specifier.identifier isEqualToString:@"apppath"]) {
			((UILabel *)[self valueLabel]).numberOfLines = 4;
		}
	}

	return self;
}

@end

@interface SRListItemsController : PSListItemsController
@end

@implementation SRListItemsController

-(void)viewWillDisappear:(BOOL)arg1 {

	[[NSUserDefaults standardUserDefaults] synchronize];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.sharedroutine.inorotate.settingschanged"), NULL, NULL, TRUE);
}

-(id)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	PSTableCell *cell = (PSTableCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];

	if (cell) {

		int orientation = [self orientationForString:cell.textLabel.text];
		if ([[self getSelectedCellsFromSettings:((PSSpecifier *)[self specifier]).identifier] containsObject:@(orientation)]) {
			[cell setChecked:TRUE];
		}
	}

	return cell;
}

-(NSArray *)getSelectedCellsFromSettings:(NSString *)identifier {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *domain = [[defaults persistentDomainForName:@"com.sharedroutine.inorotate"] mutableCopy] ?: [NSMutableDictionary dictionary];
	NSDictionary *settings = domain[identifier] ?: [NSDictionary dictionary];
	return settings[@"kAllowedOrientations"] ?: @[];
}

-(void)updateSettingsWithSelectedItem:(NSNumber *)item wantsRemove:(BOOL)remove forDisplayIdentifier:(NSString *)identifier {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *domain = [[defaults persistentDomainForName:@"com.sharedroutine.inorotate"] mutableCopy] ?: [NSMutableDictionary dictionary];
	NSMutableDictionary *settings = [domain[identifier] mutableCopy] ?: [NSMutableDictionary dictionary];
	NSMutableArray *allowedOrientations = [settings[@"kAllowedOrientations"] mutableCopy] ?: [@[] mutableCopy];
	NSInteger index = [allowedOrientations indexOfObject:item];

	if (index != NSNotFound && remove) {
		[allowedOrientations removeObjectAtIndex:index];
	} else {
		[allowedOrientations addObject:item];
	}

	[settings setObject:allowedOrientations forKey:@"kAllowedOrientations"];
	[domain setObject:settings forKey:identifier];
	[defaults setPersistentDomain:domain forName:@"com.sharedroutine.inorotate"];
}

-(void)listItemSelected:(NSIndexPath *)indexPath {

	PSTableCell *selectedCell = (PSTableCell *)[((UITableView *)[self table]) cellForRowAtIndexPath:indexPath];
	BOOL checked = [selectedCell isChecked];
	[selectedCell setChecked:!checked];
	[self updateSettingsWithSelectedItem:@([self orientationForString:[selectedCell _automationID]]) wantsRemove:checked forDisplayIdentifier:((PSSpecifier *)[self specifier]).identifier];
}

-(int)orientationForString:(NSString *)string {

	if ([string isEqualToString:@"UIInterfaceOrientationPortrait"]) {
		return 1;
	} else if ([string isEqualToString:@"UIInterfaceOrientationPortraitUpsideDown"]) {
		return 2;
	} else if ([string isEqualToString:@"UIInterfaceOrientationLandscapeLeft"]) {
		return 3;
	} else if ([string isEqualToString:@"UIInterfaceOrientationLandscapeRight"]) {
		return 4;
	} else {
		return -1;
	}
}

@end

@implementation AppSettingsListController
@synthesize bundleIdentifier = _bundleIdentifier;
@synthesize applicationName = _applicationName;
@synthesize userDefaults = _userDefaults;
@synthesize appIcon = _appIcon;
@synthesize appVersion = _appVersion;
@synthesize appPath = _appPath;


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

	if (indexPath.section != 0) return 44.0f;

	PSSpecifier *spec = [self specifiers][indexPath.row+1];

	if ([spec.identifier isEqualToString:@"appname"]) {

		return IPAD ? 80.0f : 90.0f;

	} else if ([spec.identifier isEqualToString:@"apppath"]) {

		return IPAD ? 60.0f : 120.0f;
	
	} else {

		return 44.0f;
	}

}

-(void)setAllowAnyOrientation:(NSNumber *)value forSpecifier:(PSSpecifier *)spec {
	NSMutableDictionary *domain = [[self.userDefaults persistentDomainForName:@"com.sharedroutine.inorotate"] mutableCopy] ?: [NSMutableDictionary dictionary];
	NSMutableDictionary *settings = [domain[self.bundleIdentifier] mutableCopy] ?: [NSMutableDictionary dictionary];
	[settings setObject:value forKey:@"kAnyDirection"];
	[domain setObject:settings forKey:self.bundleIdentifier];
	[self.userDefaults setPersistentDomain:domain forName:@"com.sharedroutine.inorotate"];
	[self.userDefaults synchronize];
	//update specifier
	PSSpecifier *selectionSpec = [self specifierForID:@"allowed_orientations"];
	[selectionSpec setProperty:@(![value boolValue]) forKey:@"enabled"];
	[self reloadSpecifier:selectionSpec];
}

-(NSNumber *)getAllowAnyOrientationForSpecifier:(PSSpecifier *)spec {
	NSDictionary *domain = [self.userDefaults persistentDomainForName:@"com.sharedroutine.inorotate"];
	return [domain[self.bundleIdentifier] objectForKey:@"kAnyDirection"] ?: @(YES);
}

-(NSString *)getAppInfoForSpecifier:(PSSpecifier *)spec {
	
	if ([spec.identifier isEqualToString:@"appname"]) {
		return self.applicationName;
	} else if ([spec.identifier isEqualToString:@"bundleid"]) {
		return self.bundleIdentifier;
	} else if ([spec.identifier isEqualToString:@"appversion"]) {
		return self.appVersion;
	} else if ([spec.identifier isEqualToString:@"apppath"]) {
		return self.appPath;
	} else {
		return @"";
	}
}

-(void)openApplicationForSpecifier:(PSSpecifier *)spec {

	if (![[LSApplicationWorkspace defaultWorkspace] openApplicationWithBundleID:self.bundleIdentifier]) {
		NSLog(@"Could not open App.");
	}
}

-(void)viewDidLoad {

	[super viewDidLoad];

	[((PSSpecifier *)[self specifierForID:@"allowed_orientations"]) setIdentifier:self.bundleIdentifier];
	[self reloadSpecifierID:self.bundleIdentifier];

	if ([self getAllowAnyOrientationForSpecifier:[self specifierForID:@"anydirection"]] == kCFBooleanTrue) {
		[((PSSpecifier *)[self specifierForID:@"allowed_orientations"]) setProperty:@(NO) forKey:@"enabled"];
		[self reloadSpecifierID:@"allowed_orientations"];
	}
}


-(id)specifiers {

	if (_specifiers == nil) {

		_specifiers = (NSArray *)[self loadSpecifiersFromPlistName:@"AppSettings" target:self];

		PSSpecifier *spec = [self specifier];
		self->_appIcon = [spec propertyForKey:@"bigIconImage"];
		self->_appPath = [spec propertyForKey:@"kAppPath"];
		self->_appVersion = [spec propertyForKey:@"kAppVersion"];
		self->_userDefaults = [NSUserDefaults standardUserDefaults];
		self->_bundleIdentifier = [spec identifier];
		self->_applicationName = [spec name];

		[((PSSpecifier *)[self specifierForID:@"appname"]) setProperty:self.appIcon forKey:@"iconImage"];
		[self reloadSpecifierID:@"appname"];
		self.title = self.applicationName;

	}

	return _specifiers;
}

@end