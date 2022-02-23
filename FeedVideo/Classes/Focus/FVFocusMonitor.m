//
//  FVFocusMonitor.m
//  FeedVideo
//
//  Created by Mark on 2019/9/25.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVFocusMonitor.h"
#import "FVWeakReference.h"
#import "FVRunLoopObserver.h"
#import "UIView+FVAdditions.h"
#import <objc/runtime.h>
#import "FVFeedVideoUtil.h"
#import "FVContext.h"

#define CHECK_DISABLE_AND_RETURN if (self.disable) { return; }
#define CHECK_DISABLE_IN_BLOCK_AND_RETURN if (strong_self.disable) { return; }

NS_INLINE void notify(void (^block)(void)) {
    // 为什么异步执行回调呢，因为找到当前聚焦视图的时候是在 kCFRunLoopBeforeWaiting
    // 这个时候向外抛事件更新 UI 时是不可靠的，因为 UIKit 更新视图依赖了 runloop，我们的 observer 优先级比 UIKit 更低，这个时候已经更新结束，因此做视图添加更新并不靠谱
    // 统一切到下一个 runloop 进行事件外抛
    dispatch_async(dispatch_get_main_queue(), ^{
        block();
    });
}

static NSString *const kTriggerKey = @"kTriggerKey";
static NSString *const kAppointKey = @"kAppointKey";

@interface FVFocusMonitor () <FVFocusTriggerDelegate>
@property (nonatomic, assign) NSUInteger focusCursor;
@property (nonatomic, readwrite, nullable) __kindof UIView *focus;
@property (nonatomic, readwrite, nullable) __kindof UIView *abort;
@property (nonatomic, strong) FVRunLoopObserver *defaultModeObserver;
@property (nonatomic, strong) FVRunLoopObserver *trackingModeObserver;
/// 记录下下一步操作, 因为 makeFocus 不是同步完成的
@property (nonatomic, copy) void (^triggerBlock)(void);
@end

@implementation FVFocusMonitor

#pragma mark - Public

- (void)appointNode:(FVIndexPathNode *)node context:(nullable FVContext *)context {
    [self appointNode:node focusType:FVFocusTypeNoScroll context:context usingBlock:nil];
}

- (void)appointNode:(FVIndexPathNode *)node focusType:(FVFocusType)focusType context:(nullable FVContext *)context {
    [self appointNode:node focusType:focusType context:context usingBlock:nil];
}

- (void)appointNode:(FVIndexPathNode *)node focusType:(FVFocusType)focusType context:(nullable FVContext *)context usingBlock:(nullable FVAppointCompletionBlock)completionBlock {
    if (!node.indexPath) {
        NSParameterAssert(node.indexPath);
        return;
    }
    UIView *container = [self.calculator containerAtIndexPath:node.indexPath];
    if (!container) {
        // 如果目标视图没法找到，那么也等滚动之后再做处理
        focusType = FVFocusTypeAfterScroll;
    }
    switch (focusType) {
        case FVFocusTypeAfterScroll: {
            // 先记录下 node，等回调再处理
            [self recordTriggerBlock:node focusType:focusType context:context completionBlock:completionBlock];
            [self.calculator makeIndexPathFocus:node.indexPath];
        }
            break;
        case FVFocusTypeNoScroll: {
            [self didFindTarget:container node:node isAppoint:YES focusType:focusType context:context usingBlock:completionBlock];
        }
            break;
        case FVFocusTypeScroll: {
            [self didFindTarget:container node:node isAppoint:YES focusType:focusType context:context usingBlock:completionBlock];
            [self.calculator makeIndexPathFocus:node.indexPath];
        }
            break;
    }
}

- (void)recalculate {
    [self.trigger trigger];
}

- (void)clear {
    self.triggerBlock = nil;
    self.focus = nil;
    self.abort = nil;
}

- (void)clearAndNotify {
    [self clearAllTasks];
    [self clearFocusContainer];
}

- (void)enumerateMonitorChainReverse:(BOOL)reverse usingBlock:(void (^)(FVFocusMonitor * _Nonnull, BOOL * _Nonnull))block {
    NSParameterAssert(block);
    FVFocusMonitor *cursor = self;
    BOOL stop = NO;
    while (cursor) {
        block(cursor, &stop);
        FVFocusMonitor *monitor = reverse ? fv_getParentMonitor(cursor.ownerSupplier) : fv_getChildMonitor(cursor.focus);
        if (!monitor || stop) {
            break;
        }
        cursor = monitor;
    }
}

- (FVFocusMonitor *)tail {
    __block FVFocusMonitor *tail = nil;
    [self enumerateMonitorChainReverse:NO usingBlock:^(FVFocusMonitor * _Nonnull monitor, BOOL * _Nonnull stop) {
        tail = monitor;
    }];
    return tail;
}

#pragma mark - Init
- (instancetype)initWithTrigger:(__kindof FVFocusTrigger *)trigger calculator:(__kindof FVFocusCalculator *)calculator {
    self = [super init];
    if (self) {
        _trigger = trigger;
        _trigger.delegate = self;
        _calculator = calculator;
        _defaultModeObserver = [[FVRunLoopObserver alloc] initWithActivity:kCFRunLoopBeforeWaiting order:FVCalculationOrder mode:kCFRunLoopDefaultMode];
        _trackingModeObserver = [[FVRunLoopObserver alloc] initWithActivity:kCFRunLoopBeforeWaiting order:FVCalculationOrder - 1 mode:kCFRunLoopCommonModes];
        [_calculator.visibleContainers enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            fv_setParentMonitor(obj, self);
            obj._fv_isDisplay = YES;
        }];
    }
    return self;
}

- (BOOL (^)(__kindof UIView *focusContainer, __kindof UIView *target))shouldChangeFocusContainerToTarget {
    if (!_shouldChangeFocusContainerToTarget) {
        __weak typeof(self) weakSelf = self;
        _shouldChangeFocusContainerToTarget = ^(__kindof UIView *focusContainer, __kindof UIView *target) {
            if (![focusContainer conformsToProtocol:@protocol(FVPlayerContainer)]) {
                return YES;
            }
            if (![target conformsToProtocol:@protocol(FVPlayerContainer)]) {
                return YES;
            }
            /**
             supplier嵌套的场景，存在播放器已经移除，但是focusContainer还没有置空的情况。
             这里对于同一个target，就不禁止切换了，逻辑上也是合理的
             */
            if (focusContainer == target) {
                return YES;
            }
            if (!weakSelf.calculator.viewVisibilityChecker(focusContainer)) {
                return YES;
            }
            return NO;
        };
    }
    return _shouldChangeFocusContainerToTarget;
}

#pragma mark - Setter & Getter
- (void)setTrigger:(__kindof FVFocusTrigger *)trigger {
    if (_trigger) {
        [_trigger stop];
        _trigger.delegate = nil;
        _trigger = nil;
    }
    _trigger = trigger;
    _trigger.delegate = self;
    [_trigger start];
}

- (void)setFocus:(__kindof UIView *)focusContainer {
    _focus = focusContainer;
    ++self.focusCursor;
}

- (void)setCalculator:(__kindof FVFocusCalculator *)calculator {
    _calculator = calculator;
}

- (void)setDisable:(BOOL)disable {
    if (disable == _disable) {
        return;
    }
    _disable = disable;
    if (!_disable && self.focus && !self.focus._fv_isDisplay) {
        [self clearFocusContainer];
    }
}

- (NSIndexPath *)focusIndexPath {
    if (!self.focus) {
        return nil;
    }
    return [self.calculator indexPathForContainer:self.focus];
}

- (FVIndexPathNode *)focusIndexPathNode {
    NSIndexPath *indexPath = self.focusIndexPath;
    if (!indexPath) {
        return nil;
    }
    FVIndexPathNode *node = FVIndexPathNode.fv_root(indexPath);
    node.child = fv_getChildMonitor(self.focus).focusIndexPathNode;
    return node;
}

- (NSIndexPath *)abortIndexPath {
    if (!self.abort) {
        return nil;
    }
    return [self.calculator indexPathForContainer:self.abort];
}

- (FVIndexPathNode *)abortIndexPathNode {
    NSIndexPath *indexPath = self.abortIndexPath;
    if (!indexPath) {
        return nil;
    }
    FVIndexPathNode *node = FVIndexPathNode.fv_root(indexPath);
    node.child = fv_getChildMonitor(self.abort).abortIndexPathNode;
    return node;
}

#pragma mark - VFPFocusTriggerDelegate
- (void)trigger:(nonnull FVFocusTrigger *)trigger viewDidEndDisplaying:(nonnull __kindof UIView *)view indexPath:(nonnull NSIndexPath *)indexPath {
    if (![view conformsToProtocol:@protocol(FVPlayerContainer)] && ![view conformsToProtocol:@protocol(FVContainerSupplier)]) {
        return;
    }
    
    view._fv_isDisplay = NO;
    UIView<FVPlayerContainer> *tailContainer = self.tail.focus;
        
    if (view == self.focus && [tailContainer conformsToProtocol:@protocol(FVPlayerContainer)]) {
        NSString *lastIdentifier = tailContainer._fv_lastIdentifier;
        NSUInteger focusCursor = self.focusCursor;
        view._fv_willEndDisplaying = YES;
        NSParameterAssert(lastIdentifier);
        // 为什么需要需要去异步处理呢？
        // 当我们遇到 `-reloadData` 场景时，对应的视图会先不可见，再重新展示，导致播放器会在刷新时因为不可见自动移除
        // 庆幸的是，该不可见再可见的逻辑会在一次 runloop 内执行完成
        // 我们延迟下不可见的回调逻辑，在下一个 loop 再做检查
        __weak typeof(self) weak_self = self;
        [self.trackingModeObserver observeWithKey:[NSUUID UUID].UUIDString repeats:NO usingBlock:^(CFRunLoopObserverRef  _Nonnull observer, CFRunLoopActivity activity) {
            __weak typeof(weak_self) strong_self = weak_self;
            if (!strong_self) {
                return;
            }
            view._fv_willEndDisplaying = NO;
            if (!view.window || !view._fv_isDisplay) {
                // view invisible or not focus anymore.
                // just call end displaying.
                if (view == strong_self.focus) {
                    notify(^{
                        [strong_self clearFocusContainer];
                        [strong_self.delegate monitor:strong_self containerDidEndDisplay:view indexPath:indexPath];
                    });
                } else {
                    notify(^{
                        [strong_self.delegate monitor:strong_self containerDidEndDisplay:view indexPath:indexPath];
                    });
                }
                return;
            }
            if (view != strong_self.focus) {
                notify(^{
                    [strong_self.delegate monitor:strong_self containerDidEndDisplay:view indexPath:indexPath];
                    [strong_self.delegate monitor:strong_self containerWillDisplay:view indexPath:indexPath];
                });
                return;
            }
            if (view == strong_self.focus && strong_self.focusCursor != focusCursor) {
                // view == self.focusContainer && self.cursor != cursor && displaying
                // 说明新的聚焦操作已经进来了，什么都不需要处理
                return;
            }
            UIView<FVPlayerContainer> *container = strong_self.tail.focus;
            if (![container conformsToProtocol:@protocol(FVPlayerContainer)]) {
                // shouldn't come here, but anyway.
                notify(^{
                    [strong_self clearFocusContainer];
                });
                return;
            }
            NSString *currentIdentifier = container.fv_uniqueIdentifier;
            if (![currentIdentifier isEqualToString:lastIdentifier]) {
                // 当前 cell 还在展示，但是 identifier 已经修改了，说明当前 cell 发生了数据更新，清除当前聚焦
                notify(^{
                    [strong_self clearFocusContainer];
                });
            }
        }];
    } else {
        CHECK_DISABLE_AND_RETURN
        [self.delegate monitor:self containerDidEndDisplay:view indexPath:indexPath];
    }
}

- (void)trigger:(nonnull FVFocusTrigger *)trigger viewWillDisplay:(nonnull __kindof UIView *)view indexPath:(nonnull NSIndexPath *)indexPath {
    if (![view conformsToProtocol:@protocol(FVPlayerContainer)] && ![view conformsToProtocol:@protocol(FVContainerSupplier)]) {
        return;
    }
    fv_setParentMonitor(view, self);
    view._fv_isDisplay = YES;
    // 即将展示的视图理论上应该永远不是当前聚焦的视图，
    // 触发还在等待不可见的异步逻辑执行，
    // 那么不需要在此刻调用 `-monitor:containerWillDisplay:indexPath:` 的回调，不可见的异步逻辑会处理这个情况
    // 详见 `-trigger:viewDidEndDisplaying:indexPath:` 处理
    // should call `dispatch_async` block later.
    if (view != self.focus) {
        CHECK_DISABLE_AND_RETURN
        
        NSString *newIdentifier = [fv_findTailContainer(view) fv_uniqueIdentifier];
        NSString *oldIdentifier = [fv_findTailContainer(self.focus) _fv_lastIdentifier];
        if ([oldIdentifier isEqualToString:newIdentifier]) {
            // UICollectionView 刷新，可能换一批 cell，如果 id 一致的话自动切换
            [self didFindTarget:view node:self.focusIndexPathNode isAppoint:YES focusType:FVFocusTypeNoScroll context:nil usingBlock:nil];
        } else {
            [self.delegate monitor:self containerWillDisplay:view indexPath:indexPath];
        }
    }
}

- (void)triggerDidTrigger:(nonnull FVFocusTrigger *)trigger {
    CHECK_DISABLE_AND_RETURN
    [self clearFocusViewIfVisibilityNotSatisfied];
    // 如果当前有指定的 操作，用指定的来计算
    if (self.triggerBlock) {
        self.triggerBlock();
        self.triggerBlock = nil;
        return;
    }
    __weak typeof(self) weak_self = self;
    [self.defaultModeObserver observeWithKey:kTriggerKey repeats:NO usingBlock:^(CFRunLoopObserverRef  _Nonnull observer, CFRunLoopActivity activity) {
        __strong typeof(weak_self) strong_self = weak_self;
        if (strong_self.disable) {
            return;
        }
        [strong_self.calculator findTargetContainerWithKey:NSStringFromSelector(_cmd) usingBlock:^(__kindof UIView * _Nullable targetContainer, NSIndexPath * _Nullable indexPath) {
            if (!targetContainer || !weak_self) {
                return;
            }
            
            notify(^{
                // 修改手动点击某个非聚焦的视频进行播放，手势滑动一点距离，就会触发重新计算聚焦，切换到聚焦视频的进行播放的问题
                if (strong_self.shouldChangeFocusContainerToTarget && !strong_self.shouldChangeFocusContainerToTarget(strong_self.focus, targetContainer)) {
                    return;
                }
                [strong_self didFindTarget:targetContainer node:FVIndexPathNode.fv_root(indexPath) isAppoint:NO focusType:FVFocusTypeNoScroll context:fv_context(FVTriggerTypeAuto, nil) usingBlock:nil];
            });
        }];
    }];
}

#pragma mark - Private
- (void)recordTriggerBlock:(FVIndexPathNode *)node focusType:(FVFocusType)focusType context:(nullable FVContext *)context completionBlock:(FVAppointCompletionBlock)completionBlock {
    
    __weak typeof(self) weak_self = self;
    self.triggerBlock = ^{
        __weak typeof(weak_self) strong_self = weak_self;
        [strong_self.defaultModeObserver observeWithKey:kAppointKey repeats:NO usingBlock:^(CFRunLoopObserverRef  _Nonnull observer, CFRunLoopActivity activity) {
            UIView *target = [strong_self.calculator containerAtIndexPath:node.indexPath];
            // 如果这里还找不到指定的视图呢？
            if (target) {
                notify(^{
                    [strong_self didFindTarget:target node:node isAppoint:YES focusType:focusType context:context usingBlock:completionBlock];
                });
            }
        }];
    };
}

/// 检测下聚焦视图的可见态是否满足，不满足则认为不再展示
- (void)clearFocusViewIfVisibilityNotSatisfied {
    if (!self.focus) {
        return;
    }
    BOOL isVisible = self.calculator.viewVisibilityChecker(self.focus);
    if (!isVisible) {
        [self clearFocusContainer];
    }
}

- (void)clearAllTasks {
    self.triggerBlock = nil;
}

- (void)clearFocusContainer {
    [self didFindTarget:nil node:nil isAppoint:NO focusType:FVFocusTypeNoScroll context:nil usingBlock:nil];
}

/**
 找到目标视图调用，并回抛给代理

 @param target 找到的目标聚焦视图
 @param node 位置节点
 @param isAppoint 是否是指定触发。如果是 NO，则说明是自动触发的。
 */
- (void)didFindTarget:(__kindof UIView *)target
                 node:(FVIndexPathNode *)node
            isAppoint:(BOOL)isAppoint
            focusType:(FVFocusType)focusType
              context:(nullable FVContext *)context
           usingBlock:(FVAppointCompletionBlock)completionBlock {
    __weak typeof(self) weak_self = self;
    void (^notifyFocus)(void) = ^void (void) {
        __strong typeof(weak_self) strong_self = weak_self;
        CHECK_DISABLE_IN_BLOCK_AND_RETURN
        
        if ([target conformsToProtocol:@protocol(FVPlayerContainer)]) {
            target._fv_lastIdentifier = [(id<FVPlayerContainer>)target fv_uniqueIdentifier];
        }
        UIView *oldView = strong_self.focus;
        strong_self.focus = target;
        strong_self.abort = nil;
        if (completionBlock) {
            completionBlock(oldView, target);
        } else {
            [strong_self.delegate monitor:strong_self focusDidChange:oldView to:target context:context];
        }
    };
    
    void (^notifyAbort)(void) = ^void (void) {
        __strong typeof(weak_self) strong_self = weak_self;
        CHECK_DISABLE_IN_BLOCK_AND_RETURN
        strong_self.abort = target;
        [strong_self.delegate monitor:strong_self didAbort:target context:context];
    };
    
    void (^notifySame)(void) = ^void (void) {
        __strong typeof(weak_self) strong_self = weak_self;
        CHECK_DISABLE_IN_BLOCK_AND_RETURN
        if (completionBlock) {
            completionBlock(target, target);
        } else {
            [strong_self.delegate monitor:strong_self didFindSame:target context:context];
        }
    };
    
    if (target && target == self.focus && !target._fv_willEndDisplaying) {
        CHECK_DISABLE_AND_RETURN
        FVFocusMonitor *monitor = fv_getChildMonitor(target);
        monitor.delegate = self.delegate;
        if (monitor && node.child) {
            [monitor appointNode:node.child focusType:focusType context:context];
        } else if (monitor) {
            [monitor recalculate];
        } else {
            notifySame();
        }
        return;
    }
    
    if ([target conformsToProtocol:@protocol(FVContainerSupplier)]) {
        FVFocusMonitor *monitor = fv_getChildMonitor(target);
        monitor.delegate = self.delegate;
        if (node.child) {
            [monitor appointNode:node.child focusType:focusType context:context];
        } else {
            [monitor recalculate];
        }
        notifyFocus();
    } else {
        if (!fv_isAutoPlay(target) && !isAppoint) {
            notifyAbort();
        } else {
            notifyFocus();
        }
    }
}

@end

#import "FVCollectionViewFocusCalculator.h"
#import "FVCollectionViewFocusTrigger.h"
@implementation FVFocusMonitor (UICollectionView)

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView {
    FVCollectionViewFocusCalculator *calculator = [[FVCollectionViewFocusCalculator alloc] initWithRootView:collectionView];
    FVCollectionViewFocusTrigger *trigger = [[FVCollectionViewFocusTrigger alloc] initWithCollectionView:collectionView];
    return [self initWithTrigger:trigger calculator:calculator];
}

@end

#import "FVTableViewFocusCalculator.h"
#import "FVTableViewFocusTrigger.h"
@implementation FVFocusMonitor (UITableView)

- (instancetype)initWithTableView:(UITableView *)tableView {
    FVTableViewFocusCalculator *calculator = [[FVTableViewFocusCalculator alloc] initWithRootView:tableView];
    FVTableViewFocusTrigger *trigger = [[FVTableViewFocusTrigger alloc] initWithTableView:tableView];
    return [self initWithTrigger:trigger calculator:calculator];
}

@end
