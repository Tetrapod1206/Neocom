//
//  NCDBInvType+NC.h
//  Develop
//
//  Created by Artem Shimanski on 12.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBInvType+CoreDataClass.h"
#import "NCFetchedCollection.h"

@interface NCDBInvType (NC)

+ (NSFetchRequest<NCDBInvType *> *)fetchRequestWithTypeID:(int32_t) typeID;
+ (NCFetchedCollection<NCDBInvType*>*) invTypesWithManagedObjectContext:(NSManagedObjectContext*) managedObjectContext;
- (NCFetchedCollection<NCDBDgmTypeAttribute*>*) attributesMap;
	
@end
