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
/// 最大允许缓存的个数，默认个数为 3
@property (nonatomic, assign) NSUInteger maximumCount;
/// 当前池子的个数
@property (nonatomic, readonly) NSUInteger count;
/// 播放器创建接口，如池子中没有可复用的播放器时，会通过该接口获取
@property (nonatomic, copy) id (^playerProvider)(NSString *identifier, NSString *type);

/// 获取单例
+ (instancetype)sharedInstance;

/// 寻找 type/identifer 一致的播放器，如找不到则返回 nil
/// @param identifier 播放器的 id
/// @param type 播放器的类型
/// @param exceptList 排除在外的播放器列表
- (nullable id)findPlayerStrictlyWithIdentifier:(NSString *)identifier type:(NSString *)type except:(nullable NSSet *)exceptList;

/// 优先寻找 type/identifer 一致的播放器，如找不到 identifier 的播放器，则随机返回一个相同类型的播放器
/// @param identifier 播放器的 id
/// @param type 播放器的类型
/// @param exceptList 排除在外的播放器列表
- (nonnull id)findPlayerRandomlyWithIdentifier:(NSString *)identifier type:(NSString *)type except:(nullable NSSet *)exceptList;

/// 淘汰指定 type/id 的播放器
/// @param identifier 播放器的 id
/// @param type 播放器的类型
- (nullable id)abortItemWithIdentifier:(NSString *)identifier type:(NSString *)type;

/// 淘汰指定类型的播放器
/// @param type 播放器的类型
- (void)abortUselessItemsForType:(NSString *)type;

/// 增加指定 type/id 的播放器的优先级，降低其被淘汰的可能
/// @param identifier 播放器的 id
/// @param type 播放器的类型
- (void)increasePriority:(NSString *)identifier type:(NSString *)type;

/// 清空整个池子
- (void)clearPool;

@end

NS_ASSUME_NONNULL_END
