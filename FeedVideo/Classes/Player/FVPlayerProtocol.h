//
//  FVPlayerProtocol.h
//  FeedVideo
//
//  Created by Mark on 2019/10/3.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@protocol FVPlayerProtocol;

NS_ASSUME_NONNULL_BEGIN

@protocol FVPlayerProtocol <NSObject>
@required
/// 当前播放器对应的视频数据
@property (nonatomic, nullable, readonly) id fv_data;
/// 播放器的视图，该视图会被添加到聚焦的 view 上
@property (nonatomic, readonly) UIView *fv_playerView;
/// 加载数据
- (void)fv_load:(id)data;
/// 预加载数据
- (void)fv_preload:(id)data;

- (void)fv_play;
- (void)fv_pause;
- (void)fv_stop;
- (void)fv_replay;

@optional
/// 播放结束的回调，如果需要实现续播策略，播放器需要实现该接口并在当前播放完成时调用该 block
@property (nonatomic, copy, nullable, setter=fv_setFinishBlock:) void(^fv_finishBlock)(id<FVPlayerProtocol> player);

@end

NS_ASSUME_NONNULL_END
