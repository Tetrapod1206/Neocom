//
//  NCDBDgmppItem.h
//  Neocom
//
//  Created by Artem Shimanski on 29.11.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBDgmppItemCategory, NCDBDgmppItemGroup, NCDBInvType, NCDBDgmppItemRequirements, NCDBDgmppItemShipResources, NCDBDgmppItemDamage;

NS_ASSUME_NONNULL_BEGIN

@interface NCDBDgmppItem : NSManagedObject

// Insert code here to declare functionality of your managed object subclass

@end

NS_ASSUME_NONNULL_END

#import "NCDBDgmppItem+CoreDataProperties.h"
