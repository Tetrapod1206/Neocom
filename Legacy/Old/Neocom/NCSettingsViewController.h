//
//  NCSettingsViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 27.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@interface NCSettingsViewController : NCTableViewController
@property (weak, nonatomic) IBOutlet UISwitch *notification24HoursSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *notification12HoursSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *notification4HoursSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *notification1HourSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *exchangeRateSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *plexSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *mineralsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *iCloudSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *loadImplantsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *saveChangesPromptSwitch;
@property (weak, nonatomic) IBOutlet UITableViewCell *databaseCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *eveCentralCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *crestCell;

- (IBAction)onChangeNotification:(id)sender;
- (IBAction)onChangeMarketPricesMonitor:(id)sender;
- (IBAction)onChangeCloud:(id)sender;
- (IBAction)onChangeLoadImplants:(id)sender;
- (IBAction)onChangeSaveChangesPrompt:(id)sender;
@end
