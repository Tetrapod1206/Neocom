//
//  NCCharacterID.h
//  Neocom
//
//  Created by Артем Шиманский on 27.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NCCharacterIDType) {
	NCCharacterIDTypeCharacter,
	NCCharacterIDTypeCorporation,
	NCCharacterIDTypeAlliance
};

@interface NCCharacterID : NSObject
@property (nonatomic, assign, readonly) NCCharacterIDType type;
@property (nonatomic, assign, readonly) int32_t characterID;
@property (nonatomic, strong, readonly) NSString* name;

//+ (id) characterIDWithName:(NSString*) name;
+ (void) requestCharacterIDWithName:(NSString*) name completionBlock:(void(^)(NCCharacterID* characterID, NSError* error)) completionBlock;

@end
