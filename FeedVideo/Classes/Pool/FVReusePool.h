//
//  VFPReusePool.h
//  FeedVideo
//
//  Created by Mark on 2019/10/7.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FVReusePool : NSObject
// 最大允许缓存的个数，默认个数为 3
@property (nonatomic, assign) NSUInteger maximumCount;
@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, copy) id (^playerProvider)(NSString *identifier, NSString *type);

+ (instancetype)sharedInstance;

- (nullable id)findPlayerStrictlyWithIdentifier:(NSString *)identifier type:(NSString *)type except:(nullable NSSet *)exceptList;

- (nonnull id)findPlayerRandomlyWithIdentifier:(NSString *)identifier type:(NSString *)type except:(nullable NSSet *)exceptList;

- (nullable id)abortItemWithIdentifier:(NSString *)identifier type:(NSString *)type;

- (BOOL)saveItem:(id)playerItem withIdentifier:(NSString *)identifier type:(NSString *)type;

- (void)abortUselessItemsForType:(NSString *)type;

- (void)increasePriority:(NSString *)identifier type:(NSString *)type;

- (void)clearPool;
@end

NS_ASSUME_NONNULL_END
