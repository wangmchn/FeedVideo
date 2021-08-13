//
//  FVFeedVideoManager.m
//  FeedVideo
//
//  Created by Mark on 2019/9/25.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVFeedVideoManager.h"
#import "FVPlayerHandler.h"
#import "FVContinueHandler.h"
#import "FVPreloadMgrProtocol.h"
#import "FVWeakReference.h"
#import "UIView+FVAdditions.h"
#import <objc/runtime.h>
#import "FVRunLoopObserver.h"
#import "FVFeedVideoUtil.h"

static NSString *const kPreloadKey = @"kPreloadKey";

@protocol FVPlayerOwnerProtocol <NSObject>
@required
- (void)fv_anotherOwner:(id<FVPlayerOwnerProtocol>)owner isRobbingPlayer:(id<FVPlayerProtocol>)player context:(nullable FVContext *)context;
@end

static inline void fv_setPlayerOwner(id<FVPlayerProtocol> player, id<FVPlayerOwnerProtocol> owner, id context) {
    if (!player) {
        return;
    }
    FVWeakReference *weak = objc_getAssociatedObject(player, fv_setPlayerOwner);
    if (weak.object == owner) {
        return;
    }
    if (!weak) {
        weak = [FVWeakReference new];
        objc_setAssociatedObject(player, fv_setPlayerOwner, weak, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    id<FVPlayerOwnerProtocol> oldOwner = weak.object;
    [oldOwner fv_anotherOwner:owner isRobbingPlayer:player context:context];
    weak.object = owner;
}

static inline void fv_enumerateVisibleContainersUsingBlock(id<FVContainerSupplier> supplier, void (^block)(UIView<FVPlayerContainer> *container, NSIndexPath *indexPath, id<FVContainerSupplier> itsSupplier)) {
    if (![supplier conformsToProtocol:@protocol(FVContainerSupplier)]) {
        return;
    }
    FVFocusMonitor *monitor = supplier.fv_focusMonitor;
    [monitor.calculator.visibleContainers enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj conformsToProtocol:@protocol(FVContainerSupplier)]) {
            fv_enumerateVisibleContainersUsingBlock(obj, block);
        } else if ([obj conformsToProtocol:@protocol(FVPlayerContainer)]) {
            block(obj, [monitor.calculator indexPathForContainer:obj], supplier);
        }
    }];
}

@interface FVFeedVideoManager () <FVFocusMonitorDelegate, FVPlayerHandlerDataSource, FVPlayerHandlerDelegate, FVPlayerOwnerProtocol>
@property (nonatomic, strong) FVContinueHandler *continueHandler;
@property (nonatomic, strong) FVRunLoopObserver *preloadObserver;
@end

@implementation FVFeedVideoManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _playerHandler = [[FVPlayerHandler alloc] init];
        _playerHandler.delegate = self;
        _playerHandler.dataSource = self;
        _continueHandler = [[FVContinueHandler alloc] init];
        __weak typeof(self) weak_self = self;
        _continueHandler.tailMonitorProvider = ^FVFocusMonitor * _Nonnull {
            __strong typeof(weak_self) strong_self = weak_self;
            return strong_self.monitor.tail;
        };
        _maximumPreloadDataCount = 3;
        _maximumPreloadPlayerCount = 2;
        _preloadObserver = [[FVRunLoopObserver alloc] initWithActivity:kCFRunLoopBeforeWaiting order:FVCalculationOrder + 1 mode:kCFRunLoopDefaultMode];
    }
    return self;
}

#pragma mark - Public
- (void)removeAllPlayers {
    [self.monitor clear];
    [self.playerHandler removeAllPlayer];
}

- (void)removePlayer:(id<FVPlayerProtocol>)player {
    [self removePlayer:player context:nil];
}

- (void)removePlayer:(id<FVPlayerProtocol>)player context:(nullable FVContext *)context {
    [self removePlayer:player pause:YES context:context];
}

- (void)removePlayer:(id<FVPlayerProtocol>)player pause:(BOOL)pause context:(nullable FVContext *)context {
    // 当前移除的播放器是聚焦的播放器，需要同步清理 monitor 的缓存数据
    UIView<FVPlayerContainer> *container = fv_getContainer(player);
    if (self.monitor.tail.focus == container) {
        [self.monitor clear];
    }
    [self.playerHandler removePlayer:player pause:pause context:context];
}

- (void)appointNode:(FVIndexPathNode *)node context:(nullable FVContext *)context {
    [self.monitor appointNode:node context:context];
}

- (void)appointNode:(FVIndexPathNode *)node player:(id<FVPlayerProtocol>)player play:(BOOL)play context:(nullable FVContext *)context {
    fv_setPlayerOwner(player, self, context);
    __weak typeof(self) weak_self = self;
    [self.monitor appointNode:node makeFocus:NO context:context usingBlock:^(__kindof UIView * _Nullable oldView, __kindof UIView * _Nullable newView) {
        __strong typeof(weak_self) strong_self = weak_self;
        if (strong_self.disable) {
            return;
        }
        if (newView == oldView) {
            [strong_self monitor:strong_self.monitor didFindSame:newView context:context];
        } else {
            [strong_self fv_monitor:strong_self.monitor focusDidChange:oldView to:newView appointPlayer:player startPlay:play context:context];
        }
    }];
}

- (void)recalculate {
    [self.monitor recalculate];
}

#pragma mark - Setter
- (void)setSupplier:(id<FVContainerSupplier>)supplier {
    if (_supplier == supplier) {
        return;
    }
    _supplier = supplier;
    if (_monitor) {
        _monitor.ownerSupplier = nil;
        _monitor.delegate = nil;
        _monitor = nil;
    }
    _monitor = fv_getChildMonitor(supplier);
    _monitor.ownerSupplier = supplier;
    _monitor.delegate = self;
    _monitor.disable = self.disable;
}

- (void)setDisable:(BOOL)disable {
    _disable = disable;
    self.monitor.disable = disable;
}

- (void)setPlayerHandler:(id<FVPlayerHandlerProtocol>)playerHandler {
    id<FVPlayerHandlerProtocol> oldHandler = _playerHandler;
    oldHandler.delegate = nil;
    oldHandler.dataSource = nil;
    
    _playerHandler = playerHandler;
    _playerHandler.delegate = self;
    _playerHandler.dataSource = self;
}

#pragma mark - Getter
- (id<FVPlayerProtocol>)focusPlayer {
    return self.playerHandler.focusPlayer;
}

#pragma mark - Private
- (void)fv_preloadDataListWithView:(__kindof UIView *)view {
    NSMutableArray *preloadDataList = [NSMutableArray array];
    [self fv_enumeratePreloadElementFromView:view usingBlock:^(id<FVPreloadProtocol> preloadElement, UIView *focusView, NSIndexPath *indexPath, BOOL *stop) {
        if (![preloadElement respondsToSelector:@selector(fv_dataPreloadListWithFocusView:indexPath:)]) {
            return;
        }
        NSArray *list = [preloadElement fv_dataPreloadListWithFocusView:focusView indexPath:indexPath];
        NSInteger allowedCount = self.maximumPreloadDataCount - preloadDataList.count;
        if (list.count > allowedCount) {
            [preloadDataList addObjectsFromArray:[list subarrayWithRange:NSMakeRange(0, allowedCount)]];
        } else {
            [preloadDataList addObjectsFromArray:list];
        }
        if (self.maximumPreloadDataCount <= preloadDataList.count) {
            *stop = YES;
        }
    }];
    if (preloadDataList.count) {
        [self.preloadMgr fv_preloadVideoDataList:preloadDataList.copy];
    }
}

- (void)fv_preloadPlayerListWithView:(__kindof UIView *)view {
    NSMutableArray *preloadPlayerList = [NSMutableArray array];
    [self fv_enumeratePreloadElementFromView:view usingBlock:^(id<FVPreloadProtocol> preloadElement, UIView *focusView, NSIndexPath *indexPath, BOOL *stop) {
        if (![preloadElement respondsToSelector:@selector(fv_playerPreloadListWithFocusView:indexPath:)]) {
            return;
        }
        NSArray *list = [preloadElement fv_playerPreloadListWithFocusView:focusView indexPath:indexPath];
        NSInteger allowedCount = self.maximumPreloadPlayerCount - preloadPlayerList.count;
        if (list.count > allowedCount) {
            [preloadPlayerList addObjectsFromArray:[list subarrayWithRange:NSMakeRange(0, allowedCount)]];
        } else {
            [preloadPlayerList addObjectsFromArray:list];
        }
        if (self.maximumPreloadPlayerCount <= preloadPlayerList.count) {
            *stop = YES;
        }
    }];
    if (preloadPlayerList.count) {
        [self.playerHandler preloadPlayerList:preloadPlayerList.copy];
    }
}

- (void)fv_enumeratePreloadElementFromView:(__kindof UIView *)view usingBlock:(void (^)(id<FVPreloadProtocol> preloadElement, UIView *focusView, NSIndexPath *indexPath, BOOL *stop))block {
    id<FVContainerSupplier> curser = view;
    if (!curser) {
        curser = self.supplier;
    }
    BOOL stop = NO;
    while (curser) {
        if ([curser conformsToProtocol:@protocol(FVContainerSupplier)]) {
            FVFocusMonitor *monitor = fv_getChildMonitor((id<FVContainerSupplier>)curser);
            UIView *view = monitor.focus ? monitor.focus : monitor.abort;
            NSIndexPath *indexPath = monitor.focus ? monitor.focusIndexPath : monitor.abortIndexPath;
            block((id<FVContainerSupplier>)curser, view, indexPath, &stop);
        }
        if (stop) {
            break;
        }
        curser = fv_getParentMonitor(curser).ownerSupplier;
    }
}

- (void)fv_enumerateResponderReverseUsingBlock:(void (^)(id responder, BOOL *stop))block {
    __block BOOL stop = NO;
    [self.monitor.tail enumerateMonitorChainReverse:YES usingBlock:^(FVFocusMonitor * _Nonnull monitor, BOOL * _Nonnull innerStop) {
        block(monitor.focus, &stop);
        if (stop) {
            *innerStop = YES;
        }
    }];
    if (!stop) {
        block(self.supplier, &stop);
    }
}

- (void)fv_monitor:(FVFocusMonitor *)monitor
     focusDidChange:(nullable __kindof UIView *)oldView
                 to:(nullable __kindof UIView *)newView
      appointPlayer:(id<FVPlayerProtocol>)player
          startPlay:(BOOL)startPlay
            context:(nullable FVContext *)context {
    // STEP 1.
    // 如果原先聚焦视图是一个嵌套容器提供者，需要找到尾部真正的播放器容器，并清理掉链上的代理
    UIView<FVPlayerContainer> *resign = nil;
    if (fv_getChildMonitor(oldView)) {
        __block FVFocusMonitor *tail = nil;
        [fv_getChildMonitor(oldView) enumerateMonitorChainReverse:NO usingBlock:^(FVFocusMonitor * _Nonnull obj, BOOL * _Nonnull stop) {
            obj.delegate = nil;
            tail = obj;
        }];
        resign = tail.focus;
    } else {
        resign = oldView;
    }
    
    // STEP 2.
    // 如果新的聚焦视图是一个嵌套容器的话，需要找到尾部真正的播放器容器，并设置监听链上的代理
    __block FVFocusMonitor *tail = nil;
    [monitor enumerateMonitorChainReverse:NO usingBlock:^(FVFocusMonitor * _Nonnull obj, BOOL * _Nonnull stop) {
        obj.delegate = self;
        tail = obj;
    }];
    UIView<FVPlayerContainer> *become = tail.focus;
    
    // STEP 3.
    // 抛给 playerHandler
    NSAssert(!become || [become conformsToProtocol:@protocol(FVPlayerContainer)], @"New Tail container: %@ must conform protocol: FVPlayerContainer", become);
    NSAssert(!resign || [resign conformsToProtocol:@protocol(FVPlayerContainer)], @"Old Tail container: %@ must conform protocol: FVPlayerContainer", resign);
    if (resign) {
        [self.playerHandler containerDidResignFocus:resign context:context];
    }
    if (become) {
        // 播放器真正被加上去的时候才会调用播放器预加载
        if ([self.playerHandler containerDidBecomeFocus:become appointPlayer:player startPlay:startPlay context:context]) {
            [self preloadListInDefaultModeWithView:become];
        } else {
            [monitor clear];
        }
    }
    // 取消续播
    [self.continueHandler cancelContinue];
}

- (void)preloadListInDefaultModeWithView:(__kindof UIView *)view {
    __weak typeof(self) weakSelf = self;
    [self.preloadObserver observeWithKey:kPreloadKey repeats:NO usingBlock:^(CFRunLoopObserverRef  _Nonnull observer, CFRunLoopActivity activity) {
        __strong typeof(weakSelf) strong_self = weakSelf;
        [strong_self fv_preloadDataListWithView:view];
        [strong_self fv_preloadPlayerListWithView:view];
    }];
}

#pragma mark - FVFocusMonitorDelegate
- (void)monitor:(FVFocusMonitor *)monitor focusDidChange:(nullable __kindof UIView *)oldView to:(nullable __kindof UIView *)newView context:(nullable FVContext *)context {
    if (self.disable) {
        return;
    }
    [self fv_monitor:monitor focusDidChange:oldView to:newView appointPlayer:nil startPlay:YES context:context];
}

- (void)monitor:(FVFocusMonitor *)monitor didAbort:(__kindof UIView *)view context:(nullable FVContext *)context {
    if (self.disable) {
        return;
    }
    if (monitor.tail.focus) {
        // 当前有视频播放，不需要再做数据预加载了
        return;
    }
    // 数据预加载
    FVFocusMonitor *child = fv_getChildMonitor(view);
    UIView *tail = view;
    if (child) {
        tail = child.tail.abort;
    }
    [self fv_preloadDataListWithView:tail];
}

- (void)monitor:(FVFocusMonitor *)monitor didFindSame:(__kindof UIView *)view context:(nullable FVContext *)context {
    if (self.disable) {
        return;
    }
    UIView<FVPlayerContainer> *container = monitor.tail.focus;
    NSParameterAssert([container conformsToProtocol:@protocol(FVPlayerContainer)]);
    if ([container conformsToProtocol:@protocol(FVPlayerContainer)] && ![container._fv_lastIdentifier isEqualToString:container.fv_uniqueIdentifier]) {
        [self.playerHandler containerDidResignFocus:container context:context];
        [self.playerHandler containerDidBecomeFocus:container appointPlayer:nil startPlay:YES context:context];
    }
    // 预加载
    [self preloadListInDefaultModeWithView:monitor.tail.focus];
}

- (void)monitor:(FVFocusMonitor *)monitor containerWillDisplay:(__kindof UIView *)container indexPath:(NSIndexPath *)indexPath {
    if (self.disable) {
        return;
    }
    id<FVContainerSupplier> supplier = monitor.ownerSupplier;
    if (![supplier respondsToSelector:@selector(fv_canAddPlayerWhenViewWillDisplay:)]) {
        return;
    }
    if (![supplier fv_canAddPlayerWhenViewWillDisplay:container]) {
        return;
    }
    if ([container conformsToProtocol:@protocol(FVContainerSupplier)]) {
        fv_enumerateVisibleContainersUsingBlock(container, ^(UIView<FVPlayerContainer> *obj, NSIndexPath *objIndexPath, id<FVContainerSupplier> objSupplier) {
            if ([obj conformsToProtocol:@protocol(FVPlayerContainer)]) {
                [self.playerHandler containerWillDisplay:obj forSupplier:objSupplier];
            }
        });
    } else {
        [self.playerHandler containerWillDisplay:container forSupplier:supplier];
    }
}

- (void)monitor:(FVFocusMonitor *)monitor containerDidEndDisplay:(__kindof UIView *)container indexPath:(NSIndexPath *)indexPath {
    if (self.disable) {
        return;
    }
    id<FVContainerSupplier> supplier = monitor.ownerSupplier;
    if (![supplier respondsToSelector:@selector(fv_canAddPlayerWhenViewWillDisplay:)]) {
        return;
    }
    if (![supplier fv_canAddPlayerWhenViewWillDisplay:container]) {
        return;
    }
    if ([container conformsToProtocol:@protocol(FVContainerSupplier)]) {
        fv_enumerateVisibleContainersUsingBlock(container, ^(UIView<FVPlayerContainer> *obj, NSIndexPath *objIndexPath, id<FVContainerSupplier> objSupplier) {
            if ([obj conformsToProtocol:@protocol(FVPlayerContainer)]) {
                [self.playerHandler containerDidEndDisplay:obj forSupplier:objSupplier];
            }
        });
    } else {
        [self.playerHandler containerDidEndDisplay:container forSupplier:supplier];
    }
}

#pragma mark - VFPPlayerHandlerDataSource

- (id<FVPlayerProtocol>)playerWithVideoInfo:(id)videoInfo displayingPlayerList:(NSArray<id<FVPlayerProtocol>> *)playerList {
    id<FVPlayerProtocol> player = [self.playerProvider fv_playerForVideoInfo:videoInfo displayingPlayerList:playerList];
    fv_setPlayerOwner(player, self, nil);
    return player;
}

#pragma mark - FVPlayerOwnerProtocol
/// 播放器复用可能导致已经不在这个页面了，需要移除当前 manager 的播放器
- (void)fv_anotherOwner:(id<FVPlayerOwnerProtocol>)owner isRobbingPlayer:(id<FVPlayerProtocol>)player context:(nullable FVContext *)context{
    if (owner == self) {
        return;
    }
    [self removePlayer:player context:context];
}

#pragma mark - VFPPlayerHandlerDelegate
- (void)handler:(id<FVPlayerHandlerProtocol>)handler didPlayerFinish:(id<FVPlayerProtocol>)player {
    [self.continueHandler trigger:player];
}

- (void)handler:(id<FVPlayerHandlerProtocol>)handler didFocusPlayerChange:(id<FVPlayerProtocol>)oldPlayer to:(id<FVPlayerProtocol>)newPlayer {
    if ([self.delegate respondsToSelector:@selector(playerManager:didFocusPlayerChange:to:)]) {
        [self.delegate playerManager:self didFocusPlayerChange:oldPlayer to:newPlayer];
    }
}

@end
