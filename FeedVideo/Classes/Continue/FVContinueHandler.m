//
//  FVContinueHandler.m
//  FeedVideo
//
//  Created by Mark on 2019/9/25.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVContinueHandler.h"
#import "FVContext.h"

@interface FVContinueHandler ()
@property (nonatomic, assign) NSInteger cursor;
@end

@implementation FVContinueHandler

- (void)cancelContinue {
    ++_cursor;
}

- (void)trigger:(id<FVPlayerProtocol>)sender {
    if (!self.tailMonitorProvider) {
        return;
    }
    FVFocusMonitor *tailMonitor = self.tailMonitorProvider();
    [tailMonitor enumerateMonitorChainReverse:YES usingBlock:^(FVFocusMonitor * _Nonnull monitor, BOOL * _Nonnull stop) {
        if (!monitor.focus || ![monitor.ownerSupplier conformsToProtocol:@protocol(FVContinueProtocol)]) {
            return;
        }
        FVContinuePolicy policy = [self continuePolicyFromMonitor:monitor];
        switch (policy) {
            case FVContinuePolicyNone:
                break;
            case FVContinuePolicyStop: {
                [sender fv_stop];
                *stop = YES;
            }
                break;
            case FVContinuePolicyReplay: {
                [sender fv_replay];
                *stop = YES;
            }
                break;
            case FVContinuePolicyPlayNext:
            case FVContinuePolicyRemoveAndPlayNext: {
                BOOL result = [self handlePlayNext:monitor shouldRemove:policy == FVContinuePolicyRemoveAndPlayNext];
                if (result) {
                    *stop = YES;
                }
            }
                break;
            case FVContinuePolicyRemove: {
                [monitor clearAndNotify];
                *stop = YES;
            }
                break;
        }
    }];
}

- (BOOL)handlePlayNext:(FVFocusMonitor *)monitor shouldRemove:(BOOL)shouldRemove {
    if (![monitor.ownerSupplier respondsToSelector:@selector(fv_nextNodeForPlayingView:indexPath:)]) {
        return NO;
    }
    NSIndexPath *indexPath = monitor.focusIndexPath;
    UIView *view = monitor.focus;
    FVIndexPathNode *node = [monitor.ownerSupplier fv_nextNodeForPlayingView:view indexPath:indexPath];
    if (shouldRemove) {
        [monitor clearAndNotify];
    }
    if (!node) {
        return NO;
    }
    NSInteger curser = ++self.cursor;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([self delayTimeFromMonitor:monitor] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (curser != self.cursor) {
            return;
        }
        [monitor appointNode:node afterFocus:YES context:fv_context(FVTriggerTypeContinue, nil)];
    });
    return YES;
}

- (CGFloat)delayTimeFromMonitor:(FVFocusMonitor *)monitor {
    if ([monitor.ownerSupplier respondsToSelector:@selector(fv_delayTimeForPlayingNextAtPlayingView:indexPath:)]) {
        return [monitor.ownerSupplier fv_delayTimeForPlayingNextAtPlayingView:monitor.focus indexPath:monitor.focusIndexPath];
    }
    return 0.0;
}

- (FVContinuePolicy)continuePolicyFromMonitor:(FVFocusMonitor *)monitor {
    if ([monitor.ownerSupplier respondsToSelector:@selector(fv_continuePolicyForPlayingView:indexPath:)]) {
        return [monitor.ownerSupplier fv_continuePolicyForPlayingView:monitor.focus indexPath:monitor.focusIndexPath];
    }
    return FVContinuePolicyNone;
}

@end
