//
//  NCCache.h
//  Develop
//
//  Created by Artem Shimanski on 19.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCCache+CoreDataModel.h"
@import CoreData;

//@interface NCCacheRecord<__covariant ObjectType>(NC)
//@property (readonly, getter=isExpired) BOOL expired;
//+ (NSFetchRequest<NCCacheRecord *> *)fetchRequestForKey:(NSString*) key account:(NSString*) account;
//- (ObjectType) object;
//
//@end


@interface NCCache : NSObject
@property (strong, nonatomic, readonly) NSManagedObjectContext *viewContext;
@property (strong, nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (class, nonatomic, retain) NCCache* sharedCache;

- (void)loadWithCompletionHandler:(void (^)(NSError* error))block;
- (void)performBackgroundTask:(void (^)(NSManagedObjectContext* managedObjectContext))block;
- (void)storeObject:(id<NSSecureCoding>) object forKey:(NSString*) key account:(NSString*) account date:(NSDate*) date expireDate:(NSDate*) expireDate completionHandler:(void(^)(NSManagedObjectID* objectID)) block;

@end
