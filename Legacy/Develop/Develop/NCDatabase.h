//
//  NCDatabase.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NCDatabase+CoreDataModel.h"
#import "NCDBInvType+NC.h"

@interface NCDatabase : NSObject
@property (strong, nonatomic, readonly) NSManagedObjectContext *viewContext;
@property (strong, nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (class, nonatomic, retain) NCDatabase* sharedDatabase;

//+ (instancetype) sharedDatabase;
- (void)loadWithCompletionHandler:(void (^)(NSError* error))block;
- (void)performBackgroundTask:(void (^)(NSManagedObjectContext* managedObjectContext))block;
- (void)performTaskAndWait:(void (^)(NSManagedObjectContext* managedObjectContext))block;

@end
