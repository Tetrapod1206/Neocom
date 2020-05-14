//
//  NCShoppingGroup.m
//  Neocom
//
//  Created by Артем Шиманский on 01.04.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCShoppingGroup.h"
#import "NCShoppingItem.h"
#import "NCShoppingList.h"
#import "NCDatabase.h"
#import "NCShoppingItem+Neocom.h"


@implementation NCShoppingGroup

@dynamic name;
@dynamic quantity;
@dynamic immutable;
@dynamic identifier;
@dynamic shoppingItems;
@dynamic shoppingList;
@dynamic iconFile;

- (NSString*) defaultIdentifier {
	if (self.immutable) {
		NSMutableString* identifier = [NSMutableString new];
		for (NCShoppingItem* item in [[self.shoppingItems allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"typeID" ascending:YES]]])
			[identifier appendFormat:@"%d:%d;", item.typeID, item.quantity];
		return identifier;
	}
	else {
		NCShoppingItem* item = [self.shoppingItems anyObject];
		NSManagedObjectContext* context = [[NCDatabase sharedDatabase] createManagedObjectContext];
		__block int32_t marketGroupID = 0;
		[context performBlockAndWait:^{
			NCDBInvMarketGroup* marketGroup;
			NCDBInvType* type = [context invTypeWithTypeID:item.typeID];
			for (marketGroup = type.marketGroup; marketGroup.parentGroup; marketGroup = marketGroup.parentGroup);
			if (marketGroup)
				marketGroupID = marketGroup.marketGroupID;
		}];
		if (marketGroupID)
			return [NSString stringWithFormat:@"%d", marketGroupID];
		else
			return @"none";
	}
}

@end
