//
//  NCFittingFitPickerViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 03.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@class NCShipFit;
@interface NCFittingFitPickerViewController : NCTableViewController
@property (nonatomic, strong) NCShipFit* selectedFit;
@end
