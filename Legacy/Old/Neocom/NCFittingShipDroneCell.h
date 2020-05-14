//
//  NCFittingShipDroneCell.h
//  Neocom
//
//  Created by Артем Шиманский on 29.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"

@interface NCFittingShipDroneCell : NCTableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *typeImageView;
@property (weak, nonatomic) IBOutlet UILabel *typeNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *optimalLabel;
@property (weak, nonatomic) IBOutlet UIImageView *stateImageView;
@property (weak, nonatomic) IBOutlet UIImageView *targetImageView;
@end
