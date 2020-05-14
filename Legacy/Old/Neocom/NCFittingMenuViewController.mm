//
//  NCFittingMenuViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 27.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingMenuViewController.h"
#import "NCTableViewCell.h"
#import "NCDatabaseTypePickerViewController.h"
#import "UIViewController+Neocom.h"
#import "NCStorage.h"
#import "NCShipFit.h"
#import "NCPOSFit.h"
#import "NCSpaceStructureFit.h"
#import "NSArray+Neocom.h"
#import "NCFittingShipViewController.h"
#import "NCFittingPOSViewController.h"
#import "NCFittingSpaceStructureViewController.h"
#import "NCFittingCharacterPickerViewController.h"
#import "NSString+Neocom.h"


@interface NCFittingMenuViewControllerRow : NSObject
@property (nonatomic, strong) NSManagedObjectID* loadoutID;
@property (nonatomic, assign) int32_t typeID;
@property (nonatomic, strong) NSString* loadoutName;
@property (nonatomic, strong) NSString* typeName;
@property (nonatomic, strong) NSManagedObjectID* iconID;
@property (nonatomic, strong) NCDBEveIcon* icon;
@property (nonatomic, assign) NCLoadoutCategory category;

@end

@implementation NCFittingMenuViewControllerRow

@end

@interface NCFittingMenuViewControllerSection : NSObject
@property (nonatomic, strong) NSMutableArray* rows;
@property (nonatomic, assign) int32_t groupID;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, assign) NSInteger order;
@end

@implementation NCFittingMenuViewControllerSection
@end

@interface NCFittingMenuViewController ()
@property (nonatomic, strong, readwrite) NCDatabaseTypePickerViewController* typePickerViewController;
@property (nonatomic, strong) NSMutableArray* sections;
@property (nonatomic, strong) NCDBEveIcon* defaultTypeIcon;
@property (nonatomic, assign) BOOL loading;
@end

@implementation NCFittingMenuViewController

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
	self.refreshControl = nil;
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.defaultTypeIcon = [self.databaseManagedObjectContext defaultTypeIcon];
	[self storageManagedObjectContext];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (!self.sections)
		[self reload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCFittingShipViewController"]) {
		NCFittingShipViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.fit = sender;
	}
	else if ([segue.identifier isEqualToString:@"NCFittingPOSViewController"]) {
		NCFittingPOSViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.fit = sender;
	}
	else if ([segue.identifier isEqualToString:@"NCFittingSpaceStructureViewController"]) {
		NCFittingSpaceStructureViewController* destinationViewController = segue.destinationViewController;
		destinationViewController.fit = sender;
	}
}

- (void) didChangeStorage {
	[self reload];
}

- (void) managedObjectContextDidFinishUpdate:(NSNotification *)notification {
	[super managedObjectContextDidFinishUpdate:notification];
	if ([self isViewLoaded] && self.view.window)
		[self reload];
	else
		self.sections = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? 6 : [[(NCFittingMenuViewControllerSection*) self.sections[section - 1] rows] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	if (sectionIndex == 0)
		return nil;
	else {
		NCFittingMenuViewControllerSection* section = self.sections[sectionIndex - 1];
		return section.title;
	}
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 0 ? UITableViewCellEditingStyleNone : UITableViewCellEditingStyleDelete;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NCFittingMenuViewControllerSection* section = self.sections[indexPath.section - 1];
		NCFittingMenuViewControllerRow* row = section.rows[indexPath.row];
		NCLoadout* loadout = [self.storageManagedObjectContext existingObjectWithID:row.loadoutID error:nil];
		[self.storageManagedObjectContext deleteObject:loadout];
		[self.storageManagedObjectContext save:nil];
		
		if (section.rows.count == 1) {
			[self.sections removeObjectAtIndex:indexPath.section - 1];
			[tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationMiddle];
		}
		else {
			[section.rows removeObjectAtIndex:indexPath.row];
			[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationMiddle];
		}
	}
}

#pragma mark - Table view delegate

- (BOOL) tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section != 0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (![NCStorage sharedStorage]) {
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		return;
	}
	
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	if (indexPath.section == 0) {
		if (indexPath.row == 1) {
			self.typePickerViewController.title = NSLocalizedString(@"Ships", nil);
			
			[self.typePickerViewController presentWithCategory:[self.databaseManagedObjectContext shipsCategory]
											  inViewController:self
													  fromRect:cell.bounds
														inView:cell
													  animated:YES
											 completionHandler:^(NCDBInvType *type) {
												 BOOL disableSaveChangesPrompt = [[NSUserDefaults standardUserDefaults] boolForKey:NCSettingsDisableSaveChangesPromptKey];
												 NCShipFit* fit;
												 if (disableSaveChangesPrompt) {
													 NCLoadout* loadout = [[NCLoadout alloc] initWithEntity:[NSEntityDescription entityForName:@"Loadout" inManagedObjectContext:self.storageManagedObjectContext] insertIntoManagedObjectContext:self.storageManagedObjectContext];
													 loadout.typeID = type.typeID;
													 loadout.name = type.typeName;
													 loadout.data = [[NCLoadoutData alloc] initWithEntity:[NSEntityDescription entityForName:@"LoadoutData" inManagedObjectContext:self.storageManagedObjectContext] insertIntoManagedObjectContext:self.storageManagedObjectContext];
													 [self.storageManagedObjectContext save:nil];
													 [self reload];
													 fit = [[NCShipFit alloc] initWithLoadout:loadout];
												 }
												 else
													 fit = [[NCShipFit alloc] initWithType:type];
												 [self performSegueWithIdentifier:@"NCFittingShipViewController" sender:fit];
												 [self.typePickerViewController dismissAnimated];
											 }];
		}
		else if (indexPath.row == 2) {
			self.typePickerViewController.title = NSLocalizedString(@"Control Towers", nil);
			[self.typePickerViewController presentWithCategory:[self.databaseManagedObjectContext controlTowersCategory]
											  inViewController:self
													  fromRect:cell.bounds
														inView:cell
													  animated:YES
											 completionHandler:^(NCDBInvType *type) {
												 NCPOSFit* fit;
												 BOOL disableSaveChangesPrompt = [[NSUserDefaults standardUserDefaults] boolForKey:NCSettingsDisableSaveChangesPromptKey];
												 if (disableSaveChangesPrompt) {
													 NCLoadout* loadout = [[NCLoadout alloc] initWithEntity:[NSEntityDescription entityForName:@"Loadout" inManagedObjectContext:self.storageManagedObjectContext] insertIntoManagedObjectContext:self.storageManagedObjectContext];
													 loadout.typeID = type.typeID;
													 loadout.name = type.typeName;
													 loadout.data = [[NCLoadoutData alloc] initWithEntity:[NSEntityDescription entityForName:@"LoadoutData" inManagedObjectContext:self.storageManagedObjectContext] insertIntoManagedObjectContext:self.storageManagedObjectContext];
													 [self.storageManagedObjectContext save:nil];
													 [self reload];
													fit = [[NCPOSFit alloc] initWithLoadout:loadout];
												 }
												 else
													 fit = [[NCPOSFit alloc] initWithType:type];
												 [self performSegueWithIdentifier:@"NCFittingPOSViewController" sender:fit];
												 [self.typePickerViewController dismissAnimated];
											 }];
		}
		else if (indexPath.row == 3) {
			/*NCSpaceStructureFit* fit = [[NCSpaceStructureFit alloc] initWithType:[self.databaseManagedObjectContext  invTypeWithTypeID:35834]];
			[self performSegueWithIdentifier:@"NCFittingSpaceStructureViewController" sender:fit];

			return;*/
			self.typePickerViewController.title = NSLocalizedString(@"Structures", nil);
			[self.typePickerViewController presentWithCategory:[self.databaseManagedObjectContext spaceStructuresCategory]
											  inViewController:self
													  fromRect:cell.bounds
														inView:cell
													  animated:YES
											 completionHandler:^(NCDBInvType *type) {
												 NCSpaceStructureFit* fit;
												 BOOL disableSaveChangesPrompt = [[NSUserDefaults standardUserDefaults] boolForKey:NCSettingsDisableSaveChangesPromptKey];
												 if (disableSaveChangesPrompt) {
													 NCLoadout* loadout = [[NCLoadout alloc] initWithEntity:[NSEntityDescription entityForName:@"Loadout" inManagedObjectContext:self.storageManagedObjectContext] insertIntoManagedObjectContext:self.storageManagedObjectContext];
													 loadout.typeID = type.typeID;
													 loadout.name = type.typeName;
													 loadout.data = [[NCLoadoutData alloc] initWithEntity:[NSEntityDescription entityForName:@"LoadoutData" inManagedObjectContext:self.storageManagedObjectContext] insertIntoManagedObjectContext:self.storageManagedObjectContext];
													 [self.storageManagedObjectContext save:nil];
													 [self reload];
													 fit = [[NCSpaceStructureFit alloc] initWithLoadout:loadout];
												 }
												 else
													 fit = [[NCSpaceStructureFit alloc] initWithType:type];
												 [self performSegueWithIdentifier:@"NCFittingSpaceStructureViewController" sender:fit];
												 [self.typePickerViewController dismissAnimated];
											 }];
		}
	}
	else {
		NCFittingMenuViewControllerSection* section = self.sections[indexPath.section - 1];
		NCFittingMenuViewControllerRow* row = section.rows[indexPath.row];
		NCLoadout* loadout = [self.storageManagedObjectContext existingObjectWithID:row.loadoutID error:nil];
		if (row.category == NCLoadoutCategoryShip) {
			NCShipFit* fit = [[NCShipFit alloc] initWithLoadout:loadout];
			[self performSegueWithIdentifier:@"NCFittingShipViewController" sender:fit];
		}
		else if (row.category == NCLoadoutCategorySpaceStructure) {
			NCSpaceStructureFit* fit = [[NCSpaceStructureFit alloc] initWithLoadout:loadout];
			[self performSegueWithIdentifier:@"NCFittingSpaceStructureViewController" sender:fit];
		}
		else {
			NCPOSFit* fit = [[NCPOSFit alloc] initWithLoadout:loadout];
			[self performSegueWithIdentifier:@"NCFittingPOSViewController" sender:fit];
		}
	}
}

#pragma mark - CollapsableTableViewDelegate

- (BOOL) tableView:(UITableView *)tableView canCollapsSection:(NSInteger) section {
	return section == 0 ? NO : [super tableView:tableView canCollapsSection:section];
}


#pragma mark - NCTableViewController

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0)
		return [NSString stringWithFormat:@"MenuItem%ldCell", (long)indexPath.row];
	else
		return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	if (indexPath.section > 0) {
		NCDefaultTableViewCell *cell = (NCDefaultTableViewCell*) tableViewCell;
		NCFittingMenuViewControllerSection* section = self.sections[indexPath.section - 1];
		NCFittingMenuViewControllerRow* row = section.rows[indexPath.row];
		if (!row.icon && row.iconID)
			row.icon = [self.databaseManagedObjectContext existingObjectWithID:row.iconID error:nil];
		
		cell.titleLabel.text = row.typeName;
		cell.subtitleLabel.text = row.loadoutName;
		cell.iconView.image = row.icon ? row.icon.image.image : self.defaultTypeIcon.image.image;
	}
}

- (id) identifierForSection:(NSInteger)sectionIndex {
	if (sectionIndex > 0) {
		NCFittingMenuViewControllerSection* section = self.sections[sectionIndex - 1];
		return section.groupID > 0 ? @(section.groupID) : section.title;
	}
	return nil;
}


#pragma mark - Private

- (void) reload {
	if (self.loading)
		return;
	else
		self.loading = YES;
	
	NSManagedObjectContext* storageManagedObjectContext = [[NCStorage sharedStorage] createManagedObjectContext];
	[storageManagedObjectContext performBlock:^{
		NSMutableArray* loadouts = [NSMutableArray new];
		for (NCLoadout* loadout in [storageManagedObjectContext loadouts]) {
			NCFittingMenuViewControllerRow* row = [NCFittingMenuViewControllerRow new];
			row.loadoutID = [loadout objectID];
			row.loadoutName = loadout.name;
			row.typeID = loadout.typeID;
			[loadouts addObject:row];
		};
		NSManagedObjectContext* databaseManagedObjectContext = [[NCDatabase sharedDatabase] createManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType];
		[databaseManagedObjectContext performBlock:^{
			NSMutableDictionary* shipLoadouts = [NSMutableDictionary new];
			NCFittingMenuViewControllerSection* posLoadouts;
			NCFittingMenuViewControllerSection* spaceStructuresLoadouts;
			
			for (NCFittingMenuViewControllerRow* row in loadouts) {
				NCDBInvType* type = [databaseManagedObjectContext invTypeWithTypeID:row.typeID];
				row.typeName = type.typeName;
				row.iconID = [type.icon objectID];
				NSRange range = [row.loadoutName rangeOfString:@"/"];
				if (type && row.loadoutName && range.location != NSNotFound) {
					NSString* folder = [[row.loadoutName substringToIndex:range.location] stringByDeletingExtraSpaces];
					NSString* name = [[row.loadoutName substringFromIndex:range.location + 1] stringByDeletingExtraSpaces];
					row.loadoutName = name;
					if (type.group.category.categoryID == NCCategoryIDShip)
						row.category = NCLoadoutCategoryShip;
					else if (type.group.category.categoryID == NCCategoryIDStructure)
						row.category = NCLoadoutCategorySpaceStructure;
					else
						row.category = NCLoadoutCategoryPOS;
					
					NCFittingMenuViewControllerSection* section = shipLoadouts[folder];
					if (!section) {
						section = [NCFittingMenuViewControllerSection new];
						shipLoadouts[folder] = section;
						section.title = folder;
						section.groupID = 0;
						section.rows = [NSMutableArray new];
						section.order = 0;
					}
					[section.rows addObject:row];

				}
				else if (type && type.group.category.categoryID == NCCategoryIDShip) {
					row.category = NCLoadoutCategoryShip;
					NCFittingMenuViewControllerSection* section = shipLoadouts[@(type.group.groupID)];
					if (!section) {
						section = [NCFittingMenuViewControllerSection new];
						shipLoadouts[@(type.group.groupID)] = section;
						section.title = type.group.groupName;
						section.groupID = type.group.groupID;
						section.rows = [NSMutableArray new];
						section.order = 1;
					}
					[section.rows addObject:row];
				}
				else if (type && type.group.category.categoryID == NCCategoryIDStructure) {
					row.category = NCLoadoutCategorySpaceStructure;
					if (!spaceStructuresLoadouts) {
						spaceStructuresLoadouts = [NCFittingMenuViewControllerSection new];
						spaceStructuresLoadouts.title = NSLocalizedString(@"Structures", nil);
						spaceStructuresLoadouts.groupID = type.group.category.categoryID;
						spaceStructuresLoadouts.rows = [NSMutableArray new];
						spaceStructuresLoadouts.order = 2;
					}
					[spaceStructuresLoadouts.rows addObject:row];
				}
				else if (type) {
					row.category = NCLoadoutCategoryPOS;
					if (!posLoadouts) {
						posLoadouts = [NCFittingMenuViewControllerSection new];
						posLoadouts.title = type.group.groupName;
						posLoadouts.groupID = type.group.groupID;
						posLoadouts.rows = [NSMutableArray new];
						posLoadouts.order = 3;
					}
					[posLoadouts.rows addObject:row];
				}
			}
			NSMutableArray* sections = [[[shipLoadouts allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]] mutableCopy];
			
			for (NCFittingMenuViewControllerSection* section in sections)
				[section.rows sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]]];

			if (posLoadouts.rows.count > 0) {
				[posLoadouts.rows sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]]];
				[sections addObject:posLoadouts];
			}
			if (spaceStructuresLoadouts.rows.count > 0) {
				[spaceStructuresLoadouts.rows sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]]];
				[sections addObject:spaceStructuresLoadouts];
			}
			
			dispatch_async(dispatch_get_main_queue(), ^{
				self.sections = sections;
				self.loading = NO;
				[self.tableView reloadData];
			});
		}];
	}];
}

- (NCDatabaseTypePickerViewController*) typePickerViewController {
	if (!_typePickerViewController) {
		_typePickerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NCDatabaseTypePickerViewController"];
	}
	return _typePickerViewController;
}

@end
