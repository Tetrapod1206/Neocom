//
//  NCDatabaseGroupsViewController.h
//  Neocom
//
//  Created by Artem Shimanski on 20.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NCDBInvCategory;
@interface NCDatabaseGroupsViewController : UITableViewController
@property (nonatomic, strong) NCDBInvCategory* category;
@end
