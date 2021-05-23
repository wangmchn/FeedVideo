//
//  FVContainerSupplier.h
//  FeedVideo
//
//  Created by Mark on 2019/9/25.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FVContinueProtocol.h"
#import "FVPreloadProtocol.h"

@class FVFocusMonitor;

NS_ASSUME_NONNULL_BEGIN

/**
 当该对象中，有子视图实现 FVPlayerContainer 时，需要遵循该协议
 */
@protocol FVContainerSupplier <NSObject, FVContinueProtocol, FVPreloadProtocol>
@required
@property (nonatomic, readonly) FVFocusMonitor *fv_focusMonitor;
@optional

/**
 用于计算当前视图是否满足可见条件的区域
 @discussion 该区域需要基于当前自身的坐标系，默认为 self.bounds
 */
@property (nonatomic, readonly) CGRect fv_visibleRectForSelf;

/**
 满足可见时需要的曝光比
 @discussion 默认认为竖屏大于 1/2，横屏 2/3 满足曝光比要求
 */
@property (nonatomic, readonly) CGFloat fv_satisfiedVisibleRatio;

/**
 是否允许在视图出现的时候，就把准备好的播放器添加上去
 @discussion 默认为 NO

 @param view 即将出现的视图，为 `UIView<FVPlayerContainer> *` or `UIView<FVContainerSupplier> *` 其中一种
 @return YES or NO
 */
- (BOOL)fv_canAddPlayerWhenViewWillDisplay:(__kindof UIView *)view;

@end

NS_ASSUME_NONNULL_END
