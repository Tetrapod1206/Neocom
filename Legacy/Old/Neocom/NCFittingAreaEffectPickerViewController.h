//
//  NCFittingAreaEffectPickerViewController.h
//  Neocom
//
//  Created by Shimanski Artem on 06.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@class NCDBInvType;
@interface NCFittingAreaEffectPickerViewController : NCTableViewController
@property (nonatomic, strong) NCDBInvType* selectedAreaEffect;

@end
