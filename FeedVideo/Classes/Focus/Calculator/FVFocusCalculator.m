//
//  FVFocusCalculator.m
//  FeedVideo
//
//  Created by Mark on 2019/9/25.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVFocusCalculator.h"

@implementation FVFocusCalculator

- (instancetype)initWithRootView:(__kindof UIView *)rootView {
    self = [super init];
    if (self) {
        _rootView = rootView;
    }
    return self;
}

- (BOOL (^)(__kindof UIView * _Nonnull))viewVisibilityChecker {
    if (_viewVisibilityChecker == nil) {
        __weak typeof(self) weak_self = self;
        _viewVisibilityChecker = ^BOOL(UIView *view) {
            if (!weak_self) { return NO; }
            // early return if not conforms to protocol.
            if (![view conformsToProtocol:@protocol(FVPlayerContainer)] &&
                ![view conformsToProtocol:@protocol(FVContainerSupplier)]) {
                return NO;
            }
            
            __strong typeof(weak_self) strong_self = weak_self;
            // get visible rect for root view.
            CGRect rootVisibleRect = strong_self.rootView.bounds;
            if (strong_self.visibleRectForView) {
                rootVisibleRect = strong_self.visibleRectForView(strong_self.rootView);
            }
            
            // get visible rect for view based on rootview's coordinate system.
            CGRect childVisibleRect = [view.superview convertRect:view.frame toView:strong_self.rootView];
            if ([view conformsToProtocol:@protocol(FVContainerSupplier)] && [view respondsToSelector:@selector(fv_visibleRectForSelf)]) {
                childVisibleRect = [view convertRect:[(UIView<FVContainerSupplier> *)view fv_visibleRectForSelf] toView:strong_self.rootView];
            } else if ([view conformsToProtocol:@protocol(FVPlayerContainer)]) {
                UIView *superview = [(UIView<FVPlayerContainer> *)view fv_playerContainerView];
                childVisibleRect = [superview.superview convertRect:superview.frame toView:strong_self.rootView];
            }
            
            // intersect.
            CGRect intersectionRect = CGRectIntersection(rootVisibleRect, childVisibleRect);
            if (CGRectIsNull(intersectionRect)) {
                return NO;
            }
            
            CGFloat satisfiedRatio = childVisibleRect.size.width > childVisibleRect.size.height ? 2.0/3.0 : 1.0/2.0;
            if ([view conformsToProtocol:@protocol(FVContainerSupplier)] && [view respondsToSelector:@selector(fv_satisfiedVisibleRatio)]) {
                satisfiedRatio = [(UIView<FVContainerSupplier> *)view fv_satisfiedVisibleRatio];
            } else if ([view conformsToProtocol:@protocol(FVPlayerContainer)] && [view respondsToSelector:@selector(fv_satisfiedVisibleRatio)]) {
                satisfiedRatio = [(UIView<FVPlayerContainer> *)view fv_satisfiedVisibleRatio];
            }
            
            // check display ratio.
            if ((intersectionRect.size.width * intersectionRect.size.height) / (childVisibleRect.size.width * childVisibleRect.size.height) >= satisfiedRatio) {
                return YES;
            }
            return NO;
        };
    }
    return _viewVisibilityChecker;
}

- (UIView *)containerAtIndexPath:(NSIndexPath *)indexPath {
    NSAssert(0, @"subclass: %@ must override this method!", self.class);
    return nil;
}

- (NSIndexPath *)indexPathForContainer:(__kindof UIView *)container {
    NSAssert(0, @"subclass: %@ must override this method!", self.class);
    return nil;
}

- (void)findTargetContainerWithKey:(NSString *)key usingBlock:(void (^)(__kindof UIView * _Nullable, NSIndexPath * _Nullable))resultBlock {
    NSAssert(0, @"subclass: %@ must override this method!", self.class);
    resultBlock(nil, nil);
}

- (void)makeIndexPathFocus:(NSIndexPath *)indexPath  {
    NSAssert(0, @"subclass: %@ must override this method!", self.class);
}

- (NSArray<UIView *> *)visibleContainers {
    NSAssert(0, @"subclass: %@ must override this method!", self.class);
    return nil;
}

@end
