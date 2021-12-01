//
//  UIView+Focus.m
//  FeedVideo
//
//  Created by markmwang on 2021/12/1.
//

#import "UIView+Focus.h"
#import "FVFeedVideoUtil.h"

@implementation UIView (Focus)

- (void)fv_focus {
    [self fv_focusWithContext:nil];
}

- (void)fv_focusWithContext:(nullable id)context {
    [self fv_focusWithType:FVFocusTypeScroll context:context];
}

- (void)fv_focusWithType:(FVFocusType)type context:(nullable id)context {
    if (![self conformsToProtocol:@protocol(FVPlayerContainer)] && ![self conformsToProtocol:@protocol(FVContainerSupplier)]) {
        NSAssert(0, @"'%@' can't be focus because it is not a 'FVPlayerContainer' or 'FVContainerSupplier'", self);
        return;
    }
    FVFocusMonitor *monitor = fv_getParentMonitor(self);
    UIView<FVContainerSupplier> *supplier = (UIView<FVContainerSupplier> *)monitor.ownerSupplier;
    if (![supplier conformsToProtocol:@protocol(FVContainerSupplier)]|| ![supplier isKindOfClass:UIView.class]) {
        NSAssert(0, @"view '%@' could only be focus when it has a supplier.", self);
        return;
    }
    NSIndexPath *indexPath = [monitor.calculator indexPathForContainer:self];
    if (!indexPath) {
        NSAssert(0, @"can't get indexPath for view '%@'", self);
        return;
    }
    FVIndexPathNode *node = FVIndexPathNode.fv_root(indexPath);
    [supplier fv_focusWithType:type context:context alsoNode:node];
}

- (void)fv_focusWithType:(FVFocusType)type context:(nullable id)context alsoNode:(FVIndexPathNode *)node {
    if (![self conformsToProtocol:@protocol(FVContainerSupplier)]) {
        NSAssert(0, @"'%@' can't be focus because it is not a 'FVContainerSupplier'", self);
        return;
    }
    FVFocusMonitor *monitor = fv_getParentMonitor(self);
    UIView<FVContainerSupplier> *supplier = (UIView<FVContainerSupplier> *)monitor.ownerSupplier;
    if (![supplier conformsToProtocol:@protocol(FVContainerSupplier)] || ![supplier isKindOfClass:UIView.class]) {
        /// 如果没有上一级 supplier 了，那么直接聚焦当前 supplier 的指定 node 就可以了
        [monitor appointNode:node focusType:type context:context];
        return;
    }
    NSIndexPath *indexPath = [monitor.calculator indexPathForContainer:self];
    if (!indexPath) {
        NSAssert(0, @"can't get indexPath for view '%@'", self);
        return;
    }
    FVIndexPathNode *superNode = FVIndexPathNode.fv_root(indexPath);
    superNode.child = node;
    [supplier fv_focusWithType:type context:context alsoNode:superNode];
}

@end
