//
//  NCShoppingListViewController.h
//  Neocom
//
//  Created by Artem Shimanski on 31.03.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@interface NCShoppingListViewController : NCTableViewController
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
- (IBAction)onChangeMode:(id)sender;

@end
