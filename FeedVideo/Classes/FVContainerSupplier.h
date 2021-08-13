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

/// 播放器容器提供者，用于提供当前视图的聚焦检测器（FVFocusMonitor）
/// 并对当前播放器的管理提供定制化的接口实现，例如聚焦的满足条件/续播及预加载策略等
/// 通常由承载 UITableView/UICollectionView 的 Controller/View 实现
@protocol FVContainerSupplier <NSObject, FVContinueProtocol, FVPreloadProtocol>

@required
/// 视图的聚焦检测器，用于检测当前哪个视图聚焦，即该对象决定了哪个视图应该被添加播放器进行播放
/// @discussion 如当前 Feed 实现为 UITableView/UICollectionView，可使用组件提供的 FVFocusMonitor 关于 UITableView/UICollectionView 的实现方法，如为自定义视图实现，可自行实现对应视图的 FVFocusMonitor
/// @code [[FVFocusMonitor alloc] initWithCollectionView:yourCollectionView];
/// [[FVFocusMonitor alloc] initWithTableView:yourTableView];
@property (nonatomic, readonly) FVFocusMonitor *fv_focusMonitor;

@optional

/// 用于计算当前视图是否满足可见条件的区域
/// @discussion 该区域需要基于当前自身的坐标系，默认为 self.bounds
@property (nonatomic, readonly) CGRect fv_visibleRectForSelf;

/// 满足可见时需要的曝光比
/// @discussion 默认认为竖屏大于 1/2，横屏 2/3 满足曝光比要求
@property (nonatomic, readonly) CGFloat fv_satisfiedVisibleRatio;

/// 是否允许在视图出现的时候，就把准备好的播放器添加上去
/// @discussion 默认为 NO
/// @param view 即将出现的视图，为 `UIView<FVPlayerContainer> *` or `UIView<FVContainerSupplier> *` 其中一种
/// @return YES or NO
- (BOOL)fv_canAddPlayerWhenViewWillDisplay:(__kindof UIView *)view;

@end

NS_ASSUME_NONNULL_END
