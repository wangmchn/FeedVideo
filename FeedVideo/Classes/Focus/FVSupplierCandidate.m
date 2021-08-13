//
//  FVSupplierCandidate.m
//  FeedVideo
//
//  Created by Mark on 2019/10/10.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVSupplierCandidate.h"
#import "FVFocusMonitor.h"
#import "FVFeedVideoUtil.h"

@interface FVSupplierCandidate () <FVFocusMonitorDelegate>
@property (nonatomic, copy) void (^completionBlock)(FVSupplierCandidate *, BOOL);
@end

@implementation FVSupplierCandidate

- (instancetype)initWithSupplier:(UIView<FVContainerSupplier> *)supplier node:(nonnull FVIndexPathNode *)node {
    self = [super init];
    if (self) {
        _supplier = supplier;
        _monitor = fv_getChildMonitor(supplier);
        _monitor.delegate = self;
        _node = node;
    }
    return self;
}

- (void)prepareUsingBlock:(void (^)(FVSupplierCandidate * _Nonnull, BOOL))completionBlock makeFocus:(BOOL)makeFocus {
    _completionBlock = completionBlock;
    FVIndexPathNode *child = self.node.child;
    if (child) {
        [self.monitor appointNode:child makeFocus:makeFocus context:nil];
    } else {
        [self.monitor recalculate];
    }
}

#pragma mark - FVFocusMonitorDelegate
- (void)monitor:(FVFocusMonitor *)monitor focusDidChange:(__kindof UIView *)oldView to:(__kindof UIView *)newView context:(nullable FVContext *)context {
    !self.completionBlock ?: self.completionBlock(self, NO);
}

- (void)monitor:(FVFocusMonitor *)monitor didFindSame:(__kindof UIView *)view context:(nullable FVContext *)context {
    UIView<FVPlayerContainer> *container = nil;
    if (fv_getChildMonitor(view)) {
        __block FVFocusMonitor *tail = nil;
        [fv_getChildMonitor(view) enumerateMonitorChainReverse:NO usingBlock:^(FVFocusMonitor * _Nonnull obj, BOOL * _Nonnull stop) {
            obj.delegate = nil;
            tail = obj;
        }];
        container = tail.focus;
    } else {
        container = view;
    }
    BOOL isNotAuto = NO;
    if ([container respondsToSelector:@selector(fv_isAutoPlay)]) {
        isNotAuto = !container.fv_isAutoPlay;
    }
    !self.completionBlock ?: self.completionBlock(self, isNotAuto);
}

- (void)monitor:(FVFocusMonitor *)monitor didAbort:(__kindof UIView *)view context:(nullable FVContext *)context {
    !self.completionBlock ?: self.completionBlock(self, YES);
}

- (void)monitor:(FVFocusMonitor *)monitor containerWillDisplay:(__kindof UIView *)container indexPath:(NSIndexPath *)indexPath {

}

- (void)monitor:(FVFocusMonitor *)monitor containerDidEndDisplay:(__kindof UIView *)container indexPath:(NSIndexPath *)indexPath {
    
}

@end
