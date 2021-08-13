//
//  FVContinueProtocol.h
//  FeedVideo
//
//  Created by Mark on 2019/10/3.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FVIndexPathNode.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, FVContinuePolicy) {
    /// 什么也不做
    FVContinuePolicyNone,
    /// 播下一个
    FVContinuePolicyPlayNext,
    /// 重播
    FVContinuePolicyReplay,
    /// 停止播放
    FVContinuePolicyStop,
    /// 移除播放器
    FVContinuePolicyRemove,
    /// 移除播放器并续播下一个
    FVContinuePolicyRemoveAndPlayNext,
};

@protocol FVContinueProtocol <NSObject>
@optional
/// 续播策略
/// @discussion 默认为 FVContinuePolicyNone, 当前模块不处理
/// 此时会继续向父亲节点询问策略，直到找到处理的节点，或者结束
- (FVContinuePolicy)fv_continuePolicyForPlayingView:(__kindof UIView *)view indexPath:(NSIndexPath *)indexPath;

/// 获取下一个续播的 indexPath
/// @discussion 当续播策略为 FVContinuePolicyPlayNext 时，续播模块会优先询问最顶上的模块下一个续播的位置
/// 如果返回为 nil, 则继续询问父亲节点策略，以及续播位置
/// @param view 对于当前实现协议的对象，所聚集的视图
/// @param indexPath 对于当前实现协议的对象，聚集的位置
/// @return 下一个续播位置
- (nullable FVIndexPathNode *)fv_nextNodeForPlayingView:(__kindof UIView *)view indexPath:(NSIndexPath *)indexPath;

/// 续播下一个的延时时间
/// @param view 对于当前实现协议的对象，所聚集的视图
/// @param indexPath 位置
- (CGFloat)fv_delayTimeForPlayingNextAtPlayingView:(__kindof UIView *)view indexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
