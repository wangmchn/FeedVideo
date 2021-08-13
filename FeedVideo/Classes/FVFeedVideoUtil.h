//
//  FVFeedVideoUtil.h
//  Pods
//
//  Created by Mark on 2021/5/25.
//


#ifndef FVFeedVideoUtil_h
#define FVFeedVideoUtil_h
#import "FVPlayerProtocol.h"
#import "FVPlayerContainer.h"
#import "FVWeakReference.h"
#import "FVFocusMonitor.h"
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

/// setter & getter
NS_INLINE void fv_setPlayer(UIView<FVPlayerContainer> *container, id<FVPlayerProtocol> _Nullable player) {
    objc_setAssociatedObject(container, fv_setPlayer, player, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

NS_INLINE _Nullable id<FVPlayerProtocol> fv_getPlayer(UIView<FVPlayerContainer> *container) {
    return objc_getAssociatedObject(container, fv_setPlayer);
}

NS_INLINE void fv_setContainer(id<FVPlayerProtocol> player, UIView<FVPlayerContainer> *_Nullable container) {
    FVWeakReference *weakReference = objc_getAssociatedObject(player, fv_setContainer);
    if (!weakReference) {
        weakReference = [[FVWeakReference alloc] init];
        objc_setAssociatedObject(player, fv_setContainer, weakReference, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    weakReference.object = container;
}

NS_INLINE UIView<FVPlayerContainer> *fv_getContainer(id<FVPlayerProtocol> player) {
    FVWeakReference *weakReference = objc_getAssociatedObject(player, fv_setContainer);
    return weakReference.object;
}

/// 判断当前播放器是否在 container 上
NS_INLINE BOOL fv_isOnContainer(id<FVPlayerProtocol> player, UIView<FVPlayerContainer> *container) {
    return player.fv_playerView.superview == container.fv_playerContainerView;
}

/// 当前 container 是否允许自动播放
/// @discussion 如果为 ture 则会自动添加播放器
NS_INLINE BOOL fv_isAutoPlay(UIView<FVPlayerContainer> *container) {
    BOOL isAutoPlay = YES;
    if ([container respondsToSelector:@selector(fv_isAutoPlay)]) {
        isAutoPlay = container.fv_isAutoPlay;
    }
    return isAutoPlay;
}

NS_INLINE BOOL fv_canAddPlayer(UIView<FVPlayerContainer> *container) {
    if (![container respondsToSelector:@selector(fv_canAddPlayer)]) {
        return YES;
    }
    return [container fv_canAddPlayer];
}

/// bind
NS_INLINE BOOL fv_isBind(UIView<FVPlayerContainer> *container, id<FVPlayerProtocol> player) {
    return [fv_getPlayer(container) isEqual:player] && [fv_getContainer(player) isEqual:container];
}

NS_INLINE void fv_bind(UIView<FVPlayerContainer> *container, id<FVPlayerProtocol> player) {
    fv_setPlayer(container, player);
    fv_setContainer(player, container);
}

NS_INLINE void fv_unbind(UIView<FVPlayerContainer> *container, id<FVPlayerProtocol> player) {
    fv_setPlayer(container, nil);
    fv_setContainer(player, nil);
}

/// Monitor Utils
NS_INLINE void fv_setChildMonitor(id<FVContainerSupplier> supplier, FVFocusMonitor *monitor) {
    if (!supplier) {
        return;
    }
    objc_setAssociatedObject(supplier, fv_setChildMonitor, monitor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/// 获取 supplier 的 monitor
/// @discussion 该方法不会每次都通过 FVContainerSupplier, 获取一次后即会缓存下来
/// @param supplier container 提供者
/// @return 该 supplier 的聚焦检测器
NS_INLINE FVFocusMonitor *fv_getChildMonitor(id<FVContainerSupplier> supplier) {
    if (![supplier conformsToProtocol:@protocol(FVContainerSupplier)]) {
        return nil;
    }
    FVFocusMonitor *monitor = objc_getAssociatedObject(supplier, fv_setChildMonitor);
    if (!monitor) {
        monitor = supplier.fv_focusMonitor;
        monitor.ownerSupplier = supplier;
        fv_setChildMonitor(supplier, monitor);
    }
    return monitor;
}

/// 获取检测该对象的检测器
/// @param object 为 `id<FVPlayerContainer> *` or `id<FVContainerSupplier> *` 其中一种
/// @return 检测该对象的检测器
NS_INLINE FVFocusMonitor *fv_getParentMonitor(id object) {
    FVWeakReference *weak = objc_getAssociatedObject(object, fv_getParentMonitor);
    return weak.object;
}

NS_INLINE void fv_setParentMonitor(id object, FVFocusMonitor *parent) {
    if (!object) {
        return;
    }
    FVWeakReference *weak = objc_getAssociatedObject(object, fv_getParentMonitor);
    if (weak.object == parent) {
        return;
    }
    if (!weak) {
        weak = [FVWeakReference new];
        objc_setAssociatedObject(object, fv_getParentMonitor, weak, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    weak.object = parent;
}

NS_INLINE UIView<FVPlayerContainer> *fv_findTailContainer(__kindof UIView *view) {
    if ([view conformsToProtocol:@protocol(FVPlayerContainer)]) {
        return view;
    }
    FVFocusMonitor *monitor = fv_getChildMonitor(view);
    return monitor.tail.focus;
}

NS_ASSUME_NONNULL_END
#endif /* FVFeedVideoUtil_h */
