//
//  FVFeedVideoUtil.h
//  Pods
//
//  Created by Mark on 2021/5/25.
//


#ifndef FVFeedVideoUtil_h
#define FVFeedVideoUtil_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FVPlayerProtocol.h"
#import "FVPlayerContainer.h"
#import "FVFocusMonitor.h"

NS_ASSUME_NONNULL_BEGIN

/// setter & getter
FOUNDATION_EXTERN void fv_setPlayer(UIView<FVPlayerContainer> *container, id<FVPlayerProtocol> _Nullable player);
FOUNDATION_EXTERN _Nullable id<FVPlayerProtocol> fv_getPlayer(UIView<FVPlayerContainer> *container);

FOUNDATION_EXTERN void fv_setContainer(id<FVPlayerProtocol> player, UIView<FVPlayerContainer> *_Nullable container);
FOUNDATION_EXTERN UIView<FVPlayerContainer> *fv_getContainer(id<FVPlayerProtocol> player);

/// Monitor Utils
FOUNDATION_EXTERN void fv_setChildMonitor(id<FVContainerSupplier> supplier, FVFocusMonitor *monitor);

/// 获取 supplier 的 monitor
/// @discussion 该方法不会每次都通过 FVContainerSupplier, 获取一次后即会缓存下来
/// @param supplier container 提供者
/// @return 该 supplier 的聚焦检测器
FOUNDATION_EXTERN FVFocusMonitor *fv_getChildMonitor(id<FVContainerSupplier> supplier);

/// 获取检测该对象的检测器
/// @param object 为 `id<FVPlayerContainer> *` or `id<FVContainerSupplier> *` 其中一种
/// @return 检测该对象的检测器
FOUNDATION_EXTERN FVFocusMonitor *fv_getParentMonitor(id object);
FOUNDATION_EXTERN void fv_setParentMonitor(id object, FVFocusMonitor *parent);

/// 判断当前播放器是否在 container 上
FOUNDATION_EXTERN BOOL fv_isOnContainer(id<FVPlayerProtocol> player, UIView<FVPlayerContainer> *container);

/// 当前 container 是否允许自动播放
/// @discussion 如果为 ture 则会自动添加播放器
FOUNDATION_EXTERN BOOL fv_isAutoPlay(UIView<FVPlayerContainer> *container);
FOUNDATION_EXTERN BOOL fv_canAddPlayer(UIView<FVPlayerContainer> *container);

/// bind
FOUNDATION_EXTERN BOOL fv_isBind(UIView<FVPlayerContainer> *container, id<FVPlayerProtocol> player);
FOUNDATION_EXTERN void fv_bind(UIView<FVPlayerContainer> *container, id<FVPlayerProtocol> player);
FOUNDATION_EXTERN void fv_unbind(UIView<FVPlayerContainer> *container, id<FVPlayerProtocol> player);

FOUNDATION_EXTERN UIView<FVPlayerContainer> *fv_findTailContainer(__kindof UIView *view);

NS_ASSUME_NONNULL_END
#endif /* FVFeedVideoUtil_h */
