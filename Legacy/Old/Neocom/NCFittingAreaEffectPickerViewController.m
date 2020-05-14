//
//  NCFittingAreaEffectPickerViewController.m
//  Neocom
//
//  Created by Shimanski Artem on 06.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingAreaEffectPickerViewController.h"
#import "NCTableViewCell.h"
#import "NCDatabaseTypeInfoViewController.h"

@interface NCFittingAreaEffectPickerViewController ()
@property (nonatomic, strong) NSArray* sections;
@end

@implementation NCFittingAreaEffectPickerViewController

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
	NSMutableArray* sections = [NSMutableArray new];
	NSManagedObjectContext* context = [[NCDatabase sharedDatabase] createManagedObjectContext];
	[context performBlock:^{
		NSMutableArray* blackHole = [NSMutableArray array];
		NSMutableArray* cataclysmic = [NSMutableArray array];
		NSMutableArray* magnetar = [NSMutableArray array];
		NSMutableArray* pulsar = [NSMutableArray array];
		NSMutableArray* redGiant = [NSMutableArray array];
		NSMutableArray* wolfRayet = [NSMutableArray array];
		NSMutableArray* incursion = [NSMutableArray array];
		NSMutableArray* other = [NSMutableArray array];
		
		NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"InvType"];
		request.predicate = [NSPredicate predicateWithFormat:@"group.groupID == 920"];
		request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"typeName" ascending:YES]];
		for (NCDBInvType* type in [context executeFetchRequest:request error:nil]) {
			if ([type.typeName rangeOfString:@"Black Hole Effect Beacon Class"].location != NSNotFound)
				[blackHole addObject:type];
			else if ([type.typeName rangeOfString:@"Cataclysmic Variable Effect Beacon Class"].location != NSNotFound)
				[cataclysmic addObject:type];
			else if ([type.typeName rangeOfString:@"Incursion"].location != NSNotFound)
				[incursion addObject:type];
			else if ([type.typeName rangeOfString:@"Magnetar Effect Beacon Class"].location != NSNotFound)
				[magnetar addObject:type];
			else if ([type.typeName rangeOfString:@"Pulsar Effect Beacon Class"].location != NSNotFound)
				[pulsar addObject:type];
			else if ([type.typeName rangeOfString:@"Red Giant Beacon Class"].location != NSNotFound)
				[redGiant addObject:type];
			else if ([type.typeName rangeOfString:@"Wolf Rayet Effect Beacon Class"].location != NSNotFound)
				[wolfRayet addObject:type];
			else
				[other addObject:type];
		}
		[sections addObject:[blackHole valueForKey:@"typeID"]];
		[sections addObject:[cataclysmic valueForKey:@"typeID"]];
		[sections addObject:[magnetar valueForKey:@"typeID"]];
		[sections addObject:[pulsar valueForKey:@"typeID"]];
		[sections addObject:[redGiant valueForKey:@"typeID"]];
		[sections addObject:[wolfRayet valueForKey:@"typeID"]];
		[sections addObject:[incursion valueForKey:@"typeID"]];
		[sections addObject:[other valueForKey:@"typeID"]];
		dispatch_async(dispatch_get_main_queue(), ^{
			self.sections = sections;
			[self.tableView reloadData];
		});
	}];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"Unwind"]) {
		self.selectedAreaEffect = [sender object];
	}
	else if ([segue.identifier isEqualToString:@"NCDatabaseTypeInfoViewController"]) {
		NCDatabaseTypeInfoViewController* controller;
		if ([segue.destinationViewController isKindOfClass:[UINavigationController class]])
			controller = [segue.destinationViewController viewControllers][0];
		else
			controller = segue.destinationViewController;
		
		controller.typeID = [[sender object] objectID];
	}
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    // Return the number of sections.
	return self.sections.count;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return NSLocalizedString(@"Black Hole", nil);
		case 1:
			return NSLocalizedString(@"Cataclysmic Variable", nil);
		case 2:
			return NSLocalizedString(@"Magnetar", nil);
		case 3:
			return NSLocalizedString(@"Pulsar", nil);
		case 4:
			return NSLocalizedString(@"Red Giant", nil);
		case 5:
			return NSLocalizedString(@"Wolf Rayet", nil);
		case 6:
			return NSLocalizedString(@"Incursion", nil);
		default:
			return NSLocalizedString(@"Other", nil);
	}
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	return [self.sections[section] count];
}

#pragma mark - NCTableViewController

- (id) identifierForSection:(NSInteger)section {
	return @(section);
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	return @"Cell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell *)tableViewCell forRowAtIndexPath:(NSIndexPath *)indexPath {
	NCDefaultTableViewCell *cell = (NCDefaultTableViewCell*) tableViewCell;
	
	NCDBInvType* row = [self.databaseManagedObjectContext invTypeWithTypeID:[self.sections[indexPath.section][indexPath.row] intValue]];
	cell.titleLabel.text = row.typeName;
	cell.accessoryView = self.selectedAreaEffect && self.selectedAreaEffect.typeID == row.typeID ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark"]] : nil;
	cell.object = row;
}

@end
