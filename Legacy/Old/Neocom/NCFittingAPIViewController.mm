//
//  NCFittingAPIViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 12.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingAPIViewController.h"
#import "NCTableViewCell.h"
#import <EVEAPI/EVEAPI.h>
#import "NCDatabaseTypePickerViewController.h"
#import "NCDatabaseGroupPickerViewContoller.h"
#import "NCFittingAPIFlagsViewController.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCFittingAPISearchResultsViewController.h"
#import "NCShipFit.h"
#import "NCLoadout.h"
#import "NSString+Neocom.h"

@interface NCFittingAPIViewController ()
@property (nonatomic, strong) NCDBInvType* type;
@property (nonatomic, strong) NCDBInvGroup* group;
@property (nonatomic, assign) NeocomAPIFlag flags;
@property (nonatomic, strong) NSDictionary* criteria;

@property (nonatomic, strong) NCDatabaseTypePickerViewController* typePickerViewController;
@property (nonatomic, strong) NAPILookup* lookup;
@property (nonatomic, strong) NSError* error;


- (IBAction)onClear:(id)sender;
- (IBAction)onSwitch:(id)sender;
- (void) update;
- (void) uploadFits;
@end

@implementation NCFittingAPIViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.flags = static_cast<NeocomAPIFlag>(NeocomAPIFlagComplete | NeocomAPIFlagValid);
	self.refreshControl = nil;
	[self update];
	
	NSDate* date = [[NSUserDefaults standardUserDefaults] valueForKey:NCSettingsAPINextSyncDateKey];
	if (!date || [date earlierDate:[NSDate date]] == date) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:NCSettingsAPIAlwaysUploadFitsKey])
			[self uploadFits];
		else {
			UIAlertController* controller = [UIAlertController alertControllerWithTitle:nil
																				message:NSLocalizedString(@"Would you like to make your contribution to the Neocom community by sharing your fit?", nil)
																		 preferredStyle:UIAlertControllerStyleAlert];
			[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Share this time", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				[self uploadFits];
			}]];
			[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Always share", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				[[NSUserDefaults standardUserDefaults] setBool:YES forKey:NCSettingsAPIAlwaysUploadFitsKey];
				[self uploadFits];
			}]];
			[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Don't share this time", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
				[[NSUserDefaults standardUserDefaults] setValue:[NSDate dateWithTimeIntervalSinceNow:60 * 60 * 24] forKey:NCSettingsAPIAlwaysUploadFitsKey];
			}]];
			
			[self presentViewController:controller animated:YES completion:nil];
		}
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
	if ([identifier isEqualToString:@"NCFittingAPISearchResultsViewController"])
		return self.lookup.count > 0;
	else
		return YES;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCFittingAPIFlagsViewController"]) {
		NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
		NCFittingAPIFlagsViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		if (indexPath.row == 2) {
			controller.title = NSLocalizedString(@"Weapon Type", nil);
			controller.titles = @[NSLocalizedString(@"Hybrid Weapon", nil),
												 NSLocalizedString(@"Energy Weapon", nil),
												 NSLocalizedString(@"Projectile Weapon", nil),
												 NSLocalizedString(@"Missile Launcher", nil)];
			
			controller.values = @[@(NeocomAPIFlagHybridTurrets), @(NeocomAPIFlagLaserTurrets), @(NeocomAPIFlagProjectileTurrets), @(NeocomAPIFlagMissileLaunchers)];
			controller.icons = @[[[[self.databaseManagedObjectContext eveIconWithIconFile:@"13_06"] image] image],
								 [[[self.databaseManagedObjectContext eveIconWithIconFile:@"13_10"] image] image],
								 [[[self.databaseManagedObjectContext eveIconWithIconFile:@"12_14"] image] image],
								 [[[self.databaseManagedObjectContext eveIconWithIconFile:@"12_12"] image] image]];
			controller.selectedValue = @(self.flags & (NeocomAPIFlagHybridTurrets | NeocomAPIFlagLaserTurrets | NeocomAPIFlagProjectileTurrets | NeocomAPIFlagMissileLaunchers));
		}
		else {
			controller.title = NSLocalizedString(@"Type of Tanking", nil);
			controller.titles = @[NSLocalizedString(@"Active Armor", nil), NSLocalizedString(@"Active Shield", nil), NSLocalizedString(@"Passive", nil)];
			
			controller.values = @[@(NeocomAPIFlagActiveTank | NeocomAPIFlagArmorTank),
												 @(NeocomAPIFlagActiveTank | NeocomAPIFlagShieldTank),
												 @(NeocomAPIFlagPassiveTank)];
			
			controller.icons = @[[UIImage imageNamed:@"armorRepairer"],
								 [UIImage imageNamed:@"shieldBooster"],
								 [UIImage imageNamed:@"shieldRecharge"]];
			controller.selectedValue = @(self.flags & (NeocomAPIFlagActiveTank | NeocomAPIFlagArmorTank | NeocomAPIFlagShieldTank | NeocomAPIFlagPassiveTank));
		}
	}
	else if ([segue.identifier isEqualToString:@"NCDatabaseGroupPickerViewContoller"]) {
		NCDatabaseGroupPickerViewContoller* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;

		controller.categoryID = NCShipCategoryID;
	}
	else if ([segue.identifier isEqualToString:@"NCFittingAPISearchResultsViewController"]) {
		NCFittingAPISearchResultsViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.criteria = self.criteria;
	}
	
}


- (IBAction)onAction:(id)sender {
	NSDate* nextSyncDate = [[NSUserDefaults standardUserDefaults] valueForKey:NCSettingsAPINextSyncDateKey];
	BOOL alwaysUpload =[[NSUserDefaults standardUserDefaults] boolForKey:NCSettingsAPIAlwaysUploadFitsKey];
	NSString* title = nil;
	if (nextSyncDate) {
		NSInteger timeInterval = [nextSyncDate timeIntervalSinceNow];
		if (timeInterval > 0)
			title = [NSString stringWithFormat:@"Next sync in %@", [NSString stringWithTimeLeft:timeInterval]];
	}
	
	UIAlertController* controller = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sync now", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[self uploadFits];
	}]];
	[controller addAction:[UIAlertAction actionWithTitle:alwaysUpload ? NSLocalizedString(@"Disable auto sync", nil) : NSLocalizedString(@"Enable auto sync", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[[NSUserDefaults standardUserDefaults] setBool:!alwaysUpload forKey:NCSettingsAPIAlwaysUploadFitsKey];
	}]];

	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
	}]];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		controller.modalPresentationStyle = UIModalPresentationPopover;
		[self presentViewController:controller animated:YES completion:nil];
		if ([sender isKindOfClass:[UIBarButtonItem class]])
			controller.popoverPresentationController.barButtonItem = sender;
		else {
			controller.popoverPresentationController.sourceView = sender;
			controller.popoverPresentationController.sourceRect = [sender bounds];
		}
	}
	else
		[self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? 5 : 1;
}

#pragma mark - Table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	if (indexPath.section == 0) {
		if (indexPath.row == 0) {
			self.typePickerViewController.title = NSLocalizedString(@"Ships", nil);
			[self.typePickerViewController presentWithCategory:[self.databaseManagedObjectContext shipsCategory]
											  inViewController:self
													  fromRect:cell.bounds
														inView:cell
													  animated:YES
											 completionHandler:^(NCDBInvType *type) {
												 self.type = [self.databaseManagedObjectContext invTypeWithTypeID:type.typeID];
												 [self dismissAnimated];
												 [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
												 [self update];
											 }];
		}
		else if (indexPath.row == 1) {
			[self performSegueWithIdentifier:@"NCDatabaseGroupPickerViewContoller" sender:cell];
		}
		else if (indexPath.row == 2 || indexPath.row == 3) {
			[self performSegueWithIdentifier:@"NCFittingAPIFlagsViewController" sender:cell];
		}
	}
}


#pragma mark - NCTableViewController

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0)
		return @"Cell";
	else
		return @"SearchResultsCell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell *)tableViewCell forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		NCDefaultTableViewCell *cell = (NCDefaultTableViewCell*) tableViewCell;
		cell.accessoryType = UITableViewCellAccessoryNone;
		
		if (indexPath.row < 4) {
			UIButton* clearButton = [[UIButton alloc] initWithFrame:CGRectZero];
			[clearButton setTitle:NSLocalizedString(@"Clear", nil) forState:UIControlStateNormal];
			clearButton.titleLabel.font = [UIFont systemFontOfSize:15];
			clearButton.titleLabel.textColor = [UIColor whiteColor];
			[clearButton sizeToFit];
			[clearButton addTarget:self action:@selector(onClear:) forControlEvents:UIControlEventTouchUpInside];
			
			if (indexPath.row == 0) {
				cell.subtitleLabel.text = NSLocalizedString(@"Ship", nil);
				if (!self.type) {
					cell.titleLabel.text = NSLocalizedString(@"Any Ship", nil);
					cell.iconView.image = [[[self.databaseManagedObjectContext eveIconWithIconFile:@"09_05"] image] image];
					cell.accessoryView = nil;
				}
				else {
					cell.titleLabel.text = self.type.typeName;
					cell.iconView.image = self.type.icon ? self.type.icon.image.image : [[[self.databaseManagedObjectContext defaultTypeIcon] image] image];
					cell.accessoryView = clearButton;
				}
			}
			else if (indexPath.row == 1) {
				cell.iconView.image = [[[self.databaseManagedObjectContext eveIconWithIconFile:@"09_05"] image] image];
				cell.subtitleLabel.text = NSLocalizedString(@"Ship Class", nil);
				if (!self.group) {
					cell.titleLabel.text = NSLocalizedString(@"Any Ship Class", nil);
					cell.accessoryView = nil;
				}
				else {
					cell.titleLabel.text = self.group.groupName;
					cell.accessoryView = clearButton;
				}
			}
			else if (indexPath.row == 2) {
				cell.subtitleLabel.text = NSLocalizedString(@"Weapon Type", nil);
				if (self.flags & NeocomAPIFlagHybridTurrets) {
					cell.titleLabel.text = NSLocalizedString(@"Hybrid Weapon", nil);
					cell.iconView.image = [[[self.databaseManagedObjectContext eveIconWithIconFile:@"13_06"] image] image];
					cell.accessoryView = clearButton;
				}
				else if (self.flags & NeocomAPIFlagLaserTurrets) {
					cell.titleLabel.text = NSLocalizedString(@"Energy Weapon", nil);
					cell.iconView.image = [[[self.databaseManagedObjectContext eveIconWithIconFile:@"13_10"] image] image];
					cell.accessoryView = clearButton;
				}
				else if (self.flags & NeocomAPIFlagProjectileTurrets) {
					cell.titleLabel.text = NSLocalizedString(@"Projectile Weapon", nil);
					cell.iconView.image = [[[self.databaseManagedObjectContext eveIconWithIconFile:@"12_14"] image] image];
					cell.accessoryView = clearButton;
				}
				else if (self.flags & NeocomAPIFlagMissileLaunchers) {
					cell.titleLabel.text = NSLocalizedString(@"Missile Launcher", nil);
					cell.iconView.image = [[[self.databaseManagedObjectContext eveIconWithIconFile:@"12_12"] image] image];
					cell.accessoryView = clearButton;
				}
				else {
					cell.titleLabel.text = NSLocalizedString(@"Any Weapon Type", nil);
					cell.iconView.image = [[[self.databaseManagedObjectContext eveIconWithIconFile:@"13_03"] image] image];
					cell.accessoryView = nil;
				}
			}
			else if (indexPath.row == 3) {
				cell.subtitleLabel.text = NSLocalizedString(@"Type of Tanking", nil);
				if (self.flags & NeocomAPIFlagActiveTank) {
					if (self.flags & NeocomAPIFlagArmorTank) {
						cell.titleLabel.text = NSLocalizedString(@"Active Armor", nil);
						cell.iconView.image = [UIImage imageNamed:@"armorRepairer"];
						cell.accessoryView = clearButton;
					}
					else {
						cell.titleLabel.text = NSLocalizedString(@"Active Shield", nil);
						cell.iconView.image = [UIImage imageNamed:@"shieldBooster"];
						cell.accessoryView = clearButton;
					}
				}
				else if (self.flags & NeocomAPIFlagPassiveTank) {
					cell.titleLabel.text = NSLocalizedString(@"Passive", nil);
					cell.iconView.image = [UIImage imageNamed:@"shieldRecharge"];
					cell.accessoryView = clearButton;
				}
				else {
					cell.titleLabel.text = NSLocalizedString(@"Any Type of Tanking", nil);
					cell.iconView.image = [UIImage imageNamed:@"shieldRecharge"];
					cell.accessoryView = nil;
				}
			}
		}
		else {
			if (indexPath.row == 4) {
				cell.titleLabel.text = NSLocalizedString(@"Only Cap Stable Fits", nil);
				cell.subtitleLabel.text = nil;
				cell.iconView.image = [UIImage imageNamed:@"capacitor"];
				UISwitch* switchView = [[UISwitch alloc] init];
				switchView.on = (self.flags & NeocomAPIFlagCapStable) == NeocomAPIFlagCapStable;
				[switchView addTarget:self action:@selector(onSwitch:) forControlEvents:UIControlEventValueChanged];
				cell.accessoryView = switchView;
			}
		}
	}
	else {
		NCDefaultTableViewCell *cell = (NCDefaultTableViewCell*) tableViewCell;
		if (self.lookup.count > 0) {
			cell.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ loadouts", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:self.lookup.count]];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		else if (self.error) {
			cell.titleLabel.text = [self.error localizedDescription];
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
		else {
			cell.titleLabel.text = NSLocalizedString(@"No Results", nil);
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
	}
}

#pragma mark - Unwind

- (IBAction)unwindFromGroupPicker:(UIStoryboardSegue*) segue {
	NCDatabaseGroupPickerViewContoller* sourceViewController = segue.sourceViewController;
	if (sourceViewController.selectedGroup) {
		self.group = [self.databaseManagedObjectContext existingObjectWithID:[sourceViewController.selectedGroup objectID] error:nil];
		[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
		[self update];
	}
}

- (IBAction)unwindFromAPIFlags:(UIStoryboardSegue*) segue {
	NCFittingAPIFlagsViewController* sourceViewController = segue.sourceViewController;
	if (sourceViewController.selectedValue) {
		NSInteger flags = 0;
		for (NSNumber* flag in sourceViewController.values)
			flags |= [flag integerValue];
		self.flags = static_cast<NeocomAPIFlag>((self.flags & (-1 ^ flags)) | [sourceViewController.selectedValue integerValue]);
		[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0], [NSIndexPath indexPathForRow:3 inSection:0]]  withRowAnimation:UITableViewRowAnimationFade];
		[self update];
	}

}

#pragma mark - Private

- (IBAction)onClear:(id)sender {
	UITableViewCell* cell = nil;
	for (cell = (UITableViewCell*) [sender superview]; ![cell isKindOfClass:[UITableViewCell class]] && cell; cell = (UITableViewCell*) cell.superview);
	
	NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
	
	if (indexPath.row == 0)
		self.type = nil;
	else if (indexPath.row == 1)
		self.group = nil;
	else if (indexPath.row == 2)
		self.flags = static_cast<NeocomAPIFlag>(self.flags & (-1 ^ (NeocomAPIFlagHybridTurrets | NeocomAPIFlagLaserTurrets | NeocomAPIFlagProjectileTurrets | NeocomAPIFlagMissileLaunchers)));
	else if (indexPath.row == 3)
		self.flags = static_cast<NeocomAPIFlag>(self.flags & (-1 ^ (NeocomAPIFlagActiveTank | NeocomAPIFlagArmorTank | NeocomAPIFlagShieldTank | NeocomAPIFlagPassiveTank)));
	[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	[self update];
}

- (IBAction)onSwitch:(id)sender {
	if ([sender isOn])
		self.flags = static_cast<NeocomAPIFlag>(self.flags | NeocomAPIFlagCapStable);
	else
		self.flags = static_cast<NeocomAPIFlag>(self.flags & (-1 ^ (NeocomAPIFlagCapStable)));
	[self update];
}

- (void) update {
	NSMutableDictionary* criteria = [NSMutableDictionary dictionary];
	if (self.type)
		criteria[@"typeID"] = @(self.type.typeID);
	else if (self.group)
		criteria[@"groupID"] = @(self.group.groupID);
	if (self.flags)
		criteria[@"flags"] = @(self.flags);
	
	self.criteria = criteria;

	[[NeocomAPI new] lookupWithCriteria:criteria completionBlock:^(NAPILookup *result, NSError *error) {
		self.error = error;
		self.lookup = result;
		[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
	}];
}

- (NCDatabaseTypePickerViewController*) typePickerViewController {
	if (!_typePickerViewController) {
		_typePickerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypePickerViewController"];
	}
	return _typePickerViewController;
}

- (void) uploadFits {
	NSString* userID = [[NSUserDefaults standardUserDefaults] objectForKey:NCSettingsUDIDKey];
	NSManagedObjectContext* storageManagedObjectContext = [[NCStorage sharedStorage] createManagedObjectContext];
	[storageManagedObjectContext performBlock:^{
		NSMutableDictionary* loadouts = [NSMutableDictionary new];
		
		for (NCLoadout* loadout in [storageManagedObjectContext loadouts])
			loadouts[@(loadout.typeID)] = loadout;
		NSManagedObjectContext* databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContext];
		[databaseManagedObjectContext performBlockAndWait:^{
			for (NSNumber* typeID in [loadouts allKeys]) {
				NCDBInvType* type = [databaseManagedObjectContext invTypeWithTypeID:[typeID intValue]];
				if (type.group.category.categoryID != NCShipCategoryID)
					[loadouts removeObjectForKey:typeID];
			}
		}];
		NSMutableArray* cannonicalNames = [NSMutableArray new];
		[loadouts enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NCLoadout*  _Nonnull loadout, BOOL * _Nonnull stop) {
			NCShipFit* shipFit = [[NCShipFit alloc] initWithLoadout:loadout];
			NSString* canonicalName = shipFit.canonicalName;
			if (canonicalName)
				[cannonicalNames addObject:canonicalName];
		}];
		
		[[NeocomAPI new] uploadFitsWithCannonicalNames:cannonicalNames userID:userID completionBlock:^(NAPIUpload *result, NSError *error) {
			if (!error)
				[[NSUserDefaults standardUserDefaults] setValue:[NSDate dateWithTimeIntervalSinceNow:60 * 60 * 24] forKey:NCSettingsAPINextSyncDateKey];
		}];

	}];
}

@end
