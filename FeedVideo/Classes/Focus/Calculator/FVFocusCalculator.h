//
//  FVFocusCalculator.h
//  FeedVideo
//
//  Created by Mark on 2019/9/25.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FVPlayerContainer.h"
#import "FVContainerSupplier.h"

NS_ASSUME_NONNULL_BEGIN

/// 寻找当前视图层级上，聚焦 view 的模块
/// @discussion 寻找到的 view 可能为两种类型：
///
/// 1. UIView<FVPlayerContainer> * 直接用来添加播放器的类型
///
/// 2. UIView<FVContainerSupplier> * 为嵌套场景，即承载视图内部仍有嵌套的视图
///
/// 这里因为存在嵌套的情况，找到的视图可能是两者中的一种，没法在语法上显示表明，只能用 UIView * 来承载了
@interface FVFocusCalculator <__covariant CalculateViewType : __kindof UIView *> : NSObject

/// 计算聚焦视图的根视图。寻找聚焦的子视图时，会根据该视图的坐标系进行可见性的判断。
@property (nonatomic, strong, readonly) CalculateViewType rootView;

/// 返回当前层级所以可见的容器
/// @discussion 寻找到的 view 可能为两种类型：
///
/// 1. UIView<FVPlayerContainer> * 直接用来添加播放器的类型
///
/// 2. UIView<FVContainerSupplier> * 为嵌套场景，即承载视图内部仍有嵌套的视图列表
@property (nonatomic, readonly, nullable) NSArray<__kindof UIView *> *visibleContainers;

/// 提供基于当前根视图坐标系的可见区域。
/// @discussion 因为当前视图层级可能有部分被覆盖, 例如 UINavigationBar/UITabBar。默认认为无遮挡全部可见。
@property (nonatomic, copy, nullable) CGRect (^visibleRectForView)(CalculateViewType view);

/// 判断该视图是否满足可见要求，外部可通过设置该接口来提供自定义的可见性检测算法，view 为 `UIView<FVPlayerContainer> *` or `UIView<FVContainerSupplier> *` 其中一种
/// @discussion 默认计算逻辑为：
///
/// 1. 转换当前 view 坐标系到 window 上
///
/// 2. 通过 visibleRectForKeyWindowProvider 获取计算视图的可见区域
///
/// 3. 横屏超过 2/3，竖屏超过 1/2 认为满足可见要求 (比例可由 container 定制)
@property (nonatomic, copy, null_resettable) BOOL (^viewVisibilityChecker)(__kindof UIView *container);

/// 找到当前视图层级上，应该由哪个视图来承载播放器
/// @discussion block 中返回的 targetContainer 为 `UIView<FVPlayerContainer> *` or `UIView<FVContainerSupplier> *` 其中
/// @param key 计算任务的 key，相同的 key 任务会去重，只回调一次
/// @param resultBlock 返回承载播放器的容器，它对应的位置，以及视图类型。
- (void)findTargetContainerWithKey:(NSString *)key usingBlock:(void (^)(__kindof UIView * _Nullable targetContainer, NSIndexPath *_Nullable indexPath))resultBlock;

/// 获取当前容器所在的位置
/// @discussion 如当前容器没有对应的 indexPath，则返回 nil
/// @param container 为 `UIView<FVPlayerContainer> *` or `UIView<FVContainerSupplier> *` 其中一种
/// @return NSIndexPath 位置信息
- (nullable NSIndexPath *)indexPathForContainer:(__kindof UIView *)container;

/// 获取当前位置对应的容器
/// @discussion 如当前 indexPath 没有对应合法的容器，则返回 nil
/// @param indexPath 位置信息
/// @return `UIView<FVPlayerContainer> *` or `UIView<FVContainerSupplier> *`
- (nullable __kindof UIView *)containerAtIndexPath:(NSIndexPath *)indexPath;

/// 使对应 indexPath 聚焦
/// @discussion 具体聚焦方式由子类实现
/// @param indexPath 位置信息
- (void)makeIndexPathFocus:(NSIndexPath *)indexPath;

/// 构造方法，初始化时必须传入一个根视图
/// @discussion 计算模块会根据该视图寻找当前聚焦的视图，且可见性检测会基于该视图的坐标系进行计算
/// @param rootView 聚焦搜寻的根视图
/// @return 计算器实例
- (instancetype)initWithRootView:(CalculateViewType)rootView NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
