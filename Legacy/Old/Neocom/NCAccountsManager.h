//
//  NCAccountsManager.h
//  Neocom
//
//  Created by Artem Shimanski on 18.12.13.
//  Copyright (c) 2013 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCAccount.h"
#import "NCAPIKey.h"

@class NCStorage;
@interface NCAccountsManager : NSObject
@property (nonatomic, strong, readonly) NCStorage* storage;
@property (nonatomic, strong) NSManagedObjectContext* storageManagedObjectContext;

+ (instancetype) sharedManager;
+ (void) setSharedManager:(NCAccountsManager*) manager;

- (id) initWithStorage:(NCStorage*) storage;
- (void) addAPIKeyWithKeyID:(int32_t) keyID vCode:(NSString*) vCode completionBlock:(void(^)(NSArray* accounts, NSError* error)) completionBlock;
- (void) removeAccount:(NCAccount*) account;
- (void) loadAccountsWithCompletionBlock:(void(^)(NSArray* accounts, NSArray* apiKeys)) completionBlock;
@end
