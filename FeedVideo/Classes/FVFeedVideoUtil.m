//
//  FVFeedVideoUtil.m
//  FeedVideo
//
//  Created by markmwang on 2021/12/3.
//

#import "FVFeedVideoUtil.h"
#import "FVWeakReference.h"
#import <objc/runtime.h>

static const void *fv_player_key = &fv_player_key;
static const void *fv_container_key = &fv_container_key;
static const void *fv_child_monitor_key = &fv_child_monitor_key;
static const void *fv_parent_monitor_key = &fv_parent_monitor_key;

/// setter & getter
void fv_setPlayer(UIView<FVPlayerContainer> *container, id<FVPlayerProtocol> _Nullable player) {
    objc_setAssociatedObject(container, fv_player_key, player, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

_Nullable id<FVPlayerProtocol> fv_getPlayer(UIView<FVPlayerContainer> *container) {
    return objc_getAssociatedObject(container, fv_player_key);
}

void fv_setContainer(id<FVPlayerProtocol> player, UIView<FVPlayerContainer> *_Nullable container) {
    FVWeakReference *weakReference = objc_getAssociatedObject(player, fv_container_key);
    if (!weakReference) {
        weakReference = [[FVWeakReference alloc] init];
        objc_setAssociatedObject(player, fv_container_key, weakReference, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    weakReference.object = container;
}

UIView<FVPlayerContainer> *fv_getContainer(id<FVPlayerProtocol> player) {
    FVWeakReference *weakReference = objc_getAssociatedObject(player, fv_container_key);
    return weakReference.object;
}

/// Monitor Utils
void fv_setChildMonitor(id<FVContainerSupplier> supplier, FVFocusMonitor *monitor) {
    if (!supplier) {
        return;
    }
    objc_setAssociatedObject(supplier, fv_child_monitor_key, monitor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/// 获取 supplier 的 monitor
/// @discussion 该方法不会每次都通过 FVContainerSupplier, 获取一次后即会缓存下来
/// @param supplier container 提供者
/// @return 该 supplier 的聚焦检测器
FVFocusMonitor *fv_getChildMonitor(id<FVContainerSupplier> supplier) {
    if (![supplier conformsToProtocol:@protocol(FVContainerSupplier)]) {
        return nil;
    }
    FVFocusMonitor *monitor = objc_getAssociatedObject(supplier, fv_child_monitor_key);
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
FVFocusMonitor *fv_getParentMonitor(id object) {
    FVWeakReference *weak = objc_getAssociatedObject(object, fv_parent_monitor_key);
    return weak.object;
}

void fv_setParentMonitor(id object, FVFocusMonitor *parent) {
    if (!object) {
        return;
    }
    FVWeakReference *weak = objc_getAssociatedObject(object, fv_parent_monitor_key);
    if (weak.object == parent) {
        return;
    }
    if (!weak) {
        weak = [FVWeakReference new];
        objc_setAssociatedObject(object, fv_parent_monitor_key, weak, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    weak.object = parent;
}

/// 判断当前播放器是否在 container 上
BOOL fv_isOnContainer(id<FVPlayerProtocol> player, UIView<FVPlayerContainer> *container) {
    return player.fv_playerView.superview == container.fv_playerContainerView;
}

/// 当前 container 是否允许自动播放
/// @discussion 如果为 ture 则会自动添加播放器
BOOL fv_isAutoPlay(UIView<FVPlayerContainer> *container) {
    BOOL isAutoPlay = YES;
    if ([container respondsToSelector:@selector(fv_isAutoPlay)]) {
        isAutoPlay = container.fv_isAutoPlay;
    }
    return isAutoPlay;
}

BOOL fv_canAddPlayer(UIView<FVPlayerContainer> *container) {
    if (![container respondsToSelector:@selector(fv_canAddPlayer)]) {
        return YES;
    }
    return [container fv_canAddPlayer];
}

/// bind
BOOL fv_isBind(UIView<FVPlayerContainer> *container, id<FVPlayerProtocol> player) {
    return [fv_getPlayer(container) isEqual:player] && [fv_getContainer(player) isEqual:container];
}

void fv_bind(UIView<FVPlayerContainer> *container, id<FVPlayerProtocol> player) {
    fv_setPlayer(container, player);
    fv_setContainer(player, container);
}

void fv_unbind(UIView<FVPlayerContainer> *container, id<FVPlayerProtocol> player) {
    fv_setPlayer(container, nil);
    fv_setContainer(player, nil);
}

UIView<FVPlayerContainer> *fv_findTailContainer(__kindof UIView *view) {
    if ([view conformsToProtocol:@protocol(FVPlayerContainer)]) {
        return view;
    }
    FVFocusMonitor *monitor = fv_getChildMonitor(view);
    return monitor.tail.focus;
}
