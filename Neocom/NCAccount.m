//
//  NCAccount.m
//  Neocom
//
//  Created by Admin on 04.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCAccount.h"
#import "NCStorage.h"
#import "NCCache.h"
#import "NSCache+Neocom.h"

#define NCAccountSkillPointsUpdateInterval (60.0 * 10.0)

@interface NCCacheRecord(NCAccount)
- (void) cacheResult:(EVEResult*) result;
@end

@implementation NCCacheRecord(NCAccount)

- (void) cacheResult:(EVEResult*) result {
	if (result) {
		self.data.data = result;
		self.date = result.eveapi.cacheDate;
		self.expireDate = result.eveapi.cachedUntil;
	}
	else {
		self.date = [NSDate date];
		self.expireDate = [NSDate dateWithTimeIntervalSinceNow:3];
	}
	[self.managedObjectContext save:nil];
}

@end


static NCAccount* currentAccount = nil;

@interface NCAccount()
@property (nonatomic, strong) NSCache* cache;
@property (nonatomic, strong) NSManagedObjectContext* cacheManagedObjectContext;
@end

@implementation NCAccount

@dynamic characterID;
@dynamic order;
@dynamic apiKey;
@dynamic skillPlans;
@dynamic mailBox;
@dynamic uuid;

@synthesize cache = _cache;

@synthesize activeSkillPlan = _activeSkillPlan;
@synthesize cacheManagedObjectContext = _cacheManagedObjectContext;


+ (instancetype) currentAccount {
	@synchronized(self) {
		return currentAccount;
	}
}


+ (void) setCurrentAccount:(NCAccount*) account {
	BOOL changed = NO;
	@synchronized(self) {
		changed = currentAccount != account;
		
		void (^save)() = ^() {
			if (changed) {
				currentAccount = account;
				if (account)
					[[NSUserDefaults standardUserDefaults] setValue:account.uuid forKey:NCSettingsCurrentAccountKey];
				else
					[[NSUserDefaults standardUserDefaults] removeObjectForKey:NCSettingsCurrentAccountKey];
				[[NSUserDefaults standardUserDefaults] synchronize];

				[[NSNotificationCenter defaultCenter] postNotificationName:NCCurrentAccountDidChangeNotification object:account];
			}
			
		};

		if (changed) {
			if (account && [account isFault]) {
				[[account managedObjectContext] performBlock:^{
					[account uuid];
					dispatch_async(dispatch_get_main_queue(), save);
				}];
			}
			else
				save();
		}
	}
}

- (void) awakeFromInsert {
	[super awakeFromInsert];
	self.cache = [NSCache new];
	self.mailBox = [[NCMailBox alloc] initWithEntity:[NSEntityDescription entityForName:@"MailBox" inManagedObjectContext:self.managedObjectContext]
					  insertIntoManagedObjectContext:self.managedObjectContext];
}

- (void) awakeFromFetch {
	[super awakeFromFetch];
	[self uuid];
}

- (void) willSave {
	if ([self isDeleted]) {
		[self.cacheManagedObjectContext performBlock:^{
			NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
			NSEntityDescription *entity = [NSEntityDescription entityForName:@"Record" inManagedObjectContext:self.cacheManagedObjectContext];
			[fetchRequest setEntity:entity];
			[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"recordID like %@", [NSString stringWithFormat:@"*%@*", self.uuid]]];

			NSArray *fetchedObjects = [self.cacheManagedObjectContext executeFetchRequest:fetchRequest error:nil];
			for (NCCacheRecord* record in fetchedObjects)
				[self.cacheManagedObjectContext deleteObject:record];

			[self.cacheManagedObjectContext save:nil];
		}];
	}
	
	[super willSave];
}

- (NCAccountType) accountType {
	return self.apiKey.apiKeyInfo.key.type == EVEAPIKeyTypeCorporation ? NCAccountTypeCorporate : NCAccountTypeCharacter;
}

- (NCSkillPlan*) activeSkillPlan {
	if (!_activeSkillPlan || [_activeSkillPlan isDeleted]) {
		if (self.skillPlans.count == 0) {
			_activeSkillPlan = [[NCSkillPlan alloc] initWithEntity:[NSEntityDescription entityForName:@"SkillPlan" inManagedObjectContext:self.managedObjectContext]
								   insertIntoManagedObjectContext:self.managedObjectContext];
			_activeSkillPlan.active = YES;
			_activeSkillPlan.account = self;
			_activeSkillPlan.name = NSLocalizedString(@"Default Skill Plan", nil);
		}
		else {
			NSSet* skillPlans = [self.skillPlans filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"active == YES"]];
			if (skillPlans.count == 0) {
				_activeSkillPlan = [self.skillPlans anyObject];
				_activeSkillPlan.active = YES;
			}
			else if (skillPlans.count > 1) {
				NSMutableSet* set = [[NSMutableSet alloc] initWithSet:skillPlans];
				_activeSkillPlan = [set anyObject];
				[set removeObject:_activeSkillPlan];
				for (NCSkillPlan* item in set)
					item.active = NO;
			}
			else
				_activeSkillPlan = [skillPlans anyObject];
		}
		if ([self.managedObjectContext hasChanges])
			[self.managedObjectContext save:nil];
	}
	return _activeSkillPlan;
}

- (void) setActiveSkillPlan:(NCSkillPlan *)activeSkillPlan {
	[self willChangeValueForKey:@"activeSkillPlan"];
	for (NCSkillPlan* skillPlan in self.skillPlans)
		if (![skillPlan isDeleted])
			skillPlan.active = NO;
	activeSkillPlan.active = YES;
	_activeSkillPlan = activeSkillPlan;
	[self didChangeValueForKey:@"activeSkillPlan"];
}

- (void) loadCharacterInfoWithCompletionBlock:(void(^)(EVECharacterInfo* characterInfo, NSError* error)) completionBlock {
	void (^finalize)(EVECharacterInfo*, NSError* error) = ^(EVECharacterInfo* characterInfo, NSError* error){
		if (characterInfo) {
			[self loadCharacterSheetWithCompletionBlock:^(EVECharacterSheet *characterSheet, NSError *error2) {
				if (characterSheet) {
					int32_t skillPoints = 0;
					for (EVECharacterSheetSkill* skill in characterSheet.skills)
						skillPoints += skill.skillpoints;
					characterInfo.skillPoints = skillPoints;
				}
				dispatch_async(dispatch_get_main_queue(), ^{
					if (characterInfo)
						[[NSNotificationCenter defaultCenter] postNotificationName:NCAccountDidChangeNotification object:self userInfo:@{@"characterInfo":characterInfo}];
					completionBlock(characterInfo, nil);
				});
			}];
		}
		else
			dispatch_async(dispatch_get_main_queue(), ^{
				completionBlock(characterInfo, nil);
			});
	};
	
	[self.managedObjectContext performBlock:^{
		NSString* key = [NSString stringWithFormat:@"%@.characterInfo", self.uuid];
		[self.cacheManagedObjectContext performBlock:^{
			NCCacheRecord* cacheRecord = self.cache[key];
			if (!cacheRecord)
				self.cache[key] = cacheRecord = [self.cacheManagedObjectContext cacheRecordWithRecordID:key];
			EVECharacterInfo* characterInfo = cacheRecord.data.data;
			if (!characterInfo) {
				[self.managedObjectContext performBlock:^{
					[[EVEOnlineAPI apiWithAPIKey:self.eveAPIKey cachePolicy:NSURLRequestUseProtocolCachePolicy] characterInfoWithCharacterID:self.characterID
																															 completionBlock:^(EVECharacterInfo *result, NSError *error) {
																																 [self.cacheManagedObjectContext performBlock:^{
																																	 [cacheRecord cacheResult:result];
																																 }];
																																 finalize(result, error);
																															 }
																															   progressBlock:nil];
				}];
			}
			else
				finalize(characterInfo, nil);
		}];

	}];
}

- (void) loadCharacterSheetWithCompletionBlock:(void(^)(EVECharacterSheet* characterSheet, NSError* error)) completionBlock {
	void (^finalize)(EVECharacterSheet*, NSError* error) = ^(EVECharacterSheet* characterSheet, NSError* error){
		if (characterSheet) {
			[self loadSkillQueueWithCompletionBlock:^(EVESkillQueue *skillQueue, NSError *error2) {
				if (skillQueue)
					[characterSheet attachSkillQueue:skillQueue];
				dispatch_async(dispatch_get_main_queue(), ^{
					if (characterSheet)
						[[NSNotificationCenter defaultCenter] postNotificationName:NCAccountDidChangeNotification object:self userInfo:@{@"characterSheet":characterSheet}];
					completionBlock(characterSheet, error);
				});
			}];
		}
		else
			dispatch_async(dispatch_get_main_queue(), ^{
				completionBlock(characterSheet, error);
			});
	};

	[self.managedObjectContext performBlock:^{
		NSString* key = [NSString stringWithFormat:@"%@.characterSheet", self.uuid];
		[self.cacheManagedObjectContext performBlock:^{
			NCCacheRecord* cacheRecord = self.cache[key];
			if (!cacheRecord)
				self.cache[key] = cacheRecord = [NCCacheRecord cacheRecordWithRecordID:key];
			EVECharacterSheet* characterSheet = cacheRecord.data.data;
			if (!characterSheet) {
				[self.managedObjectContext performBlock:^{
					[[EVEOnlineAPI apiWithAPIKey:self.eveAPIKey cachePolicy:NSURLRequestUseProtocolCachePolicy] characterSheetWithCompletionBlock:^(EVECharacterSheet *result, NSError *error) {
						[self.cacheManagedObjectContext performBlock:^{
							[cacheRecord cacheResult:result];
						}];
						finalize(result, error);
					}
																																	progressBlock:nil];
				}];
			}
			else
				finalize(characterSheet, nil);
		}];
	}];
}

- (void) loadCorporationSheetWithCompletionBlock:(void(^)(EVECorporationSheet* corporationSheet, NSError* error)) completionBlock {
	[self.managedObjectContext performBlock:^{
		NSString* key = [NSString stringWithFormat:@"%@.corporationSheet", self.uuid];
		[self.cacheManagedObjectContext performBlock:^{
			NCCacheRecord* cacheRecord = self.cache[key];
			if (!cacheRecord)
				self.cache[key] = cacheRecord = [NCCacheRecord cacheRecordWithRecordID:key];
			EVECorporationSheet* corporationSheet = cacheRecord.data.data;
			if (!corporationSheet) {
				[self.managedObjectContext performBlock:^{
					[[EVEOnlineAPI apiWithAPIKey:self.eveAPIKey cachePolicy:NSURLRequestUseProtocolCachePolicy] corporationSheetWithCorporationID:0
																																  completionBlock:^(EVECorporationSheet *result, NSError *error) {
																																	  [self.cacheManagedObjectContext performBlock:^{
																																		  [cacheRecord cacheResult:result];
																																	  }];
																																	  dispatch_async(dispatch_get_main_queue(), ^{
																																		  completionBlock(result, error);
																																		  if (result)
																																			  [[NSNotificationCenter defaultCenter] postNotificationName:NCAccountDidChangeNotification object:self userInfo:@{@"corporationSheet":result}];
																																		  
																																	  });
																																  }
																																	progressBlock:nil];
				}];
			}
			else {
				dispatch_async(dispatch_get_main_queue(), ^{
					completionBlock(corporationSheet, nil);
				});
			}
		}];
	}];
}

- (void) loadSkillQueueWithCompletionBlock:(void(^)(EVESkillQueue* skillQueue, NSError* error)) completionBlock {
	[self.managedObjectContext performBlock:^{
		NSString* key = [NSString stringWithFormat:@"%@.skillQueue", self.uuid];
		[self.cacheManagedObjectContext performBlock:^{
			NCCacheRecord* cacheRecord = self.cache[key];
			if (!cacheRecord)
				self.cache[key] = cacheRecord = [NCCacheRecord cacheRecordWithRecordID:key];
			EVESkillQueue* skillQueue = cacheRecord.data.data;
			if (!skillQueue) {
				[self.managedObjectContext performBlock:^{
					[[EVEOnlineAPI apiWithAPIKey:self.eveAPIKey cachePolicy:NSURLRequestUseProtocolCachePolicy] skillQueueWithCompletionBlock:^(EVESkillQueue *result, NSError *error) {
						[self.cacheManagedObjectContext performBlock:^{
							[cacheRecord cacheResult:result];
						}];
						dispatch_async(dispatch_get_main_queue(), ^{
							if (result)
								[[NSNotificationCenter defaultCenter] postNotificationName:NCAccountDidChangeNotification object:self userInfo:@{@"skillQueue":result}];
							completionBlock(result, error);
						});
					}
																																progressBlock:nil];
				}];
			}
			else {
				dispatch_async(dispatch_get_main_queue(), ^{
					completionBlock(skillQueue, nil);
				});
			}
		}];
	}];
}

- (EVEAPIKey*) eveAPIKey {
	return [EVEAPIKey apiKeyWithKeyID:self.apiKey.keyID vCode:self.apiKey.vCode characterID:self.characterID corporate:self.accountType == NCAccountTypeCorporate];
}

- (void) reloadWithCachePolicy:(NSURLRequestCachePolicy) cachePolicy completionBlock:(void(^)(NSError* error)) completionBlock progressBlock:(void(^)(float progress)) progressBlock {
	[self.managedObjectContext performBlock:^{
		NSString* uuid = self.uuid;
		EVEOnlineAPI* api = [[EVEOnlineAPI alloc] initWithAPIKey:self.eveAPIKey cachePolicy:cachePolicy];
		api.startImmediately = NO;
		NCAccountType accountType = self.accountType;
		
		[self.cacheManagedObjectContext performBlock:^{
			NSDate* currentDate = [NSDate date];

			BOOL (^updateRequired)(NCCacheRecord*) = ^(NCCacheRecord* cacheRecord) {
				if (cachePolicy == NSURLRequestReloadIgnoringLocalCacheData)
					return YES;
				else if (cachePolicy == NSURLRequestReturnCacheDataElseLoad)
					return (BOOL) (cacheRecord.data.data != nil);
				else if (cachePolicy == NSURLRequestReturnCacheDataDontLoad)
					return NO;
				else
					return (BOOL)(!cacheRecord.data.data || !cacheRecord.expireDate || [cacheRecord.expireDate compare:currentDate] == NSOrderedAscending);
			};
			
			NCCacheRecord* (^loadCacheRecord)(NSString*) = ^(NSString* key) {
				NCCacheRecord* cacheRecord = self.cache[key];
				if (!cacheRecord)
					self.cache[key] = cacheRecord = [NCCacheRecord cacheRecordWithRecordID:key];
				return cacheRecord;
			};
			
			NSMutableSet* operations = [NSMutableSet new];

			__block EVECharacterInfo* characterInfo;
			__block EVECharacterSheet* characterSheet;
			__block EVECorporationSheet* corporationSheet;
			__block EVESkillQueue* skillQueue;

			NCCacheRecord* characterInfoCacheRecord = loadCacheRecord([NSString stringWithFormat:@"%@.characterInfo", uuid]);
			characterInfo = characterInfoCacheRecord.data.data;
			if (updateRequired(characterInfoCacheRecord))
				[operations addObject:[api characterInfoWithCharacterID:self.characterID completionBlock:^(EVECharacterInfo *result, NSError *error) {
					characterInfo = result;
				} progressBlock:nil]];
			
			if (accountType == NCAccountTypeCharacter) {
				NCCacheRecord* characterSheetCacheRecord = loadCacheRecord([NSString stringWithFormat:@"%@.characterSheet", uuid]);
				characterSheet = characterSheetCacheRecord.data.data;
				if (updateRequired(characterSheetCacheRecord))
					[operations addObject:[api characterSheetWithCompletionBlock:^(EVECharacterSheet *result, NSError *error) {
						characterSheet = result;
					} progressBlock:nil]];
				
				NCCacheRecord* skillQueueCacheRecord = loadCacheRecord([NSString stringWithFormat:@"%@.skillQueue", uuid]);
				skillQueue = skillQueueCacheRecord.data.data;
				if (updateRequired(skillQueueCacheRecord))
					[operations addObject:[api skillQueueWithCompletionBlock:^(EVESkillQueue *result, NSError *error) {
						skillQueue = result;
					} progressBlock:nil]];
			}
			else {
				NCCacheRecord* corporationSheetCacheRecord = loadCacheRecord([NSString stringWithFormat:@"%@.corporationSheet", uuid]);
				corporationSheet = corporationSheetCacheRecord.data.data;
				if (updateRequired(corporationSheetCacheRecord))
					[operations addObject:[api corporationSheetWithCorporationID:0 completionBlock:^(EVECorporationSheet *result, NSError *error) {
						corporationSheet = result;
					} progressBlock:nil]];
			}
			
			if (operations.count > 0) {
				NSArray* batchedOperations = [AFHTTPRequestOperation batchOfRequestOperations:[operations allObjects]
																			 progressBlock:^void(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
																				 if (progressBlock)
																					 progressBlock((float) totalNumberOfOperations / (float) numberOfFinishedOperations);
																			 }
																		   completionBlock:^void(NSArray * operations) {
																			   NSError* error = nil;
																			   for (AFHTTPRequestOperation* operation in operations)
																				   error = error ?: operation.error;
																			   
																			   NSMutableDictionary* userInfo = [NSMutableDictionary new];
																			   
																			   if (characterSheet) {
																				   if (characterInfo) {
																					   int32_t skillPoints = 0;
																					   for (EVECharacterSheetSkill* skill in characterSheet.skills)
																						   skillPoints += skill.skillpoints;
																					   characterInfo.skillPoints = skillPoints;
																				   }
																				   if (skillQueue)
																					   [characterSheet attachSkillQueue:skillQueue];
																			   }
																			   
																			   if (characterInfo)
																				   userInfo[@"characterInfo"] = characterInfo;
																			   if (characterSheet)
																				   userInfo[@"characterSheet"] = characterSheet;
																			   if (skillQueue)
																				   userInfo[@"skillQueue"] = skillQueue;
																			   if (corporationSheet)
																				   userInfo[@"corporationSheet"] = corporationSheet;
																			   
																			   [self.cacheManagedObjectContext performBlock:^{
																				   for (NSString* item in @[@"characterInfo", @"characterSheet", @"skillQueue", @"corporationSheet"]) {
																				   //for (NSString* item in @[@"characterInfo", @"characterSheet", @"skillQueue"]) {
																					   NSString* key = [NSString stringWithFormat:@"%@.%@", uuid, item];
																					   NCCacheRecord* cacheRecord = self.cache[key];
																					   if (!cacheRecord)
																						   self.cache[key] = cacheRecord = [NCCacheRecord cacheRecordWithRecordID:key];
																					   [cacheRecord cacheResult:userInfo[item]];
																				   }
																			   }];
																			   
																			   dispatch_async(dispatch_get_main_queue(), ^{
																				   if (completionBlock)
																					   completionBlock(error);
																				   [[NSNotificationCenter defaultCenter] postNotificationName:NCAccountDidChangeNotification object:self userInfo:userInfo];
																			   });
																			   
																		   }];
				[api.httpRequestOperationManager.operationQueue addOperations:batchedOperations waitUntilFinished:NO];
			}
			else
				dispatch_async(dispatch_get_main_queue(), ^{
					completionBlock(nil);
				});
		}];
	}];
}

- (NSManagedObjectContext*) cacheManagedObjectContext {
	if (!_cacheManagedObjectContext) {
		_cacheManagedObjectContext = [[NCCache sharedCache] createManagedObjectContext];
	}
	return _cacheManagedObjectContext;
}

#pragma mark - Private

- (NSCache*) cache {
	if (!_cache) {
		@synchronized(self) {
			if (!_cache)
				_cache = [NSCache new];
		}
	}
	return _cache;
}

@end
