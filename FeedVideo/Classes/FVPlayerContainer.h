//
//  FVPlayerContainer.h
//  FeedVideo
//
//  Created by Mark on 2019/9/25.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FVPlayerProtocol.h"
@class FVContext;

NS_ASSUME_NONNULL_BEGIN

/// 承载播放器的视图容器需要遵循这个协议
@protocol FVPlayerContainer <NSObject>
@required

/// 播放器的父视图，播放器会被添加到该视图上，并且设置 frame 为这个 view 的 bounds
@property (nonatomic, readonly) UIView *fv_playerContainerView;
/// 播放所需要的数据，该数据最终会通过 -fv_load:/-fv_preload: 传给播放器
@property (nonatomic, readonly) id fv_videoInfo;
/// 当前卡片的唯一 id，因为 view 存在复用，需要实现该接口以保证在复用时播放器可以被正常移除或者转移到正确的视图上
@property (nonatomic, readonly) NSString *fv_uniqueIdentifier;

@optional
/// 是否自动播放，如不实现，则默认为自动播放
@property (nonatomic, readonly) BOOL fv_isAutoPlay;
/// 满足可见的比例，如不实现，则默认横视频为 2.0/3.0，竖视频为 1.0/2.0
@property (nonatomic, readonly) CGFloat fv_satisfiedVisibleRatio;
/// 是否可以被添加播放器，例如移动网络等特殊情况不喜欢被添加播放器时，可通过该接口控制
- (BOOL)fv_canAddPlayer;

/// 即将添加播放器回调
/// @param player 播放器
/// @param context 上下文
- (void)fv_willAddPlayer:(id<FVPlayerProtocol>)player context:(nullable FVContext *)context;
/// 添加播放器完成回调
/// @param player 播放器
/// @param context 上下文
- (void)fv_didAddPlayer:(id<FVPlayerProtocol>)player context:(nullable FVContext *)context;
/// 即将移除播放器回调
/// @param player 播放器
/// @param context 上下文
- (void)fv_willRemovePlayer:(id<FVPlayerProtocol>)player context:(nullable FVContext *)context;
/// 移除播放器完成回调
/// @param player 播放器
/// @param context 上下文
- (void)fv_didRemovePlayer:(id<FVPlayerProtocol>)player context:(nullable FVContext *)context;

@end

NS_ASSUME_NONNULL_END
