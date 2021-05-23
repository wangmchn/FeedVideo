//
//  FVCollectionViewFocusCalculator.m
//  FeedVideo
//
//  Created by Mark on 2019/9/25.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVCollectionViewFocusCalculator.h"

/// 将 indexpaths 按照 section 进行分组，并针对每个 section 按照从小到大排序
static inline NSDictionary<NSNumber *, NSArray<NSIndexPath *> *> *SortVisibleIndexPathsBySection(NSArray<NSIndexPath *> *indexPaths) {
    NSMutableDictionary<NSNumber *, NSMutableArray<NSIndexPath *> *> *sortedIndexPaths = [NSMutableDictionary dictionary];
    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableArray<NSIndexPath *> *indexPathsForSection = sortedIndexPaths[@(obj.section)];
        if (!indexPathsForSection) {
            indexPathsForSection = [NSMutableArray array];
            [sortedIndexPaths setObject:indexPathsForSection forKey:@(obj.section)];
        }
        [indexPathsForSection addObject:obj];
    }];
    
    [sortedIndexPaths enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSMutableArray<NSIndexPath *> * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj sortUsingSelector:@selector(compare:)];
    }];
    
    return sortedIndexPaths.copy;
}

static inline UIEdgeInsets fv_collectionViewEdgeInsets(UICollectionView *collectionView) {
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, tvOS 11.0, *)) {
        return collectionView.adjustedContentInset;
    } else {
        return collectionView.contentInset;
    }
#else
    return collectionView.contentInset;
#endif
}

@implementation FVCollectionViewFocusCalculator

- (instancetype)initWithRootView:(__kindof UIView *)rootView {
    self = [super initWithRootView:rootView];
    if (self) {
        _focusAnimatable = YES;
        _ignoreContentInsetsWhileMakingFocus = NO;
        _focusPosition = UICollectionViewScrollPositionCenteredVertically | UICollectionViewScrollPositionCenteredHorizontally;
    }
    return self;
}

/// 这里寻找的逻辑是:
/// 1. 先按照 section 从小到大进行遍历;
/// 2. 针对每个 section，按照 header -> items -> footer 的顺序进行查找;
/// 3. 找到第一个满足可见条件的视图返回;
- (void)findTargetContainerWithKey:(NSString *)key usingBlock:(void (^)(__kindof UIView * _Nullable, NSIndexPath * _Nullable))resultBlock {
    if (!self.rootView.window) {
        resultBlock(nil, nil);
        return;
    }
    // 先针对 header/footer/item 各自按照 section 分组
    NSDictionary<NSNumber *, NSArray<NSIndexPath *> *> *visibleItemsIndexPaths = SortVisibleIndexPathsBySection(self.rootView.indexPathsForVisibleItems);
    NSDictionary<NSNumber *, NSArray<NSIndexPath *> *> *visibleHeadersIndexPaths = nil;
    NSDictionary<NSNumber *, NSArray<NSIndexPath *> *> *visibleFootersIndexPaths = nil;
    if (@available(iOS 9, *)) {
        visibleHeadersIndexPaths = SortVisibleIndexPathsBySection([self.rootView indexPathsForVisibleSupplementaryElementsOfKind:UICollectionElementKindSectionHeader]);
        visibleFootersIndexPaths = SortVisibleIndexPathsBySection([self.rootView indexPathsForVisibleSupplementaryElementsOfKind:UICollectionElementKindSectionFooter]);
    }
   
    __block NSIndexPath *targetIndexPath = nil;
    __block UIView *targetView = nil;
       
    BOOL (^isFound)(void) = ^BOOL {
        return targetIndexPath && targetView;
    };
       
    // 寻找 section 中满足可见的视图
    void (^findTarget)(NSArray<NSIndexPath *> *, UIView *(^viewProviderBlock)(NSIndexPath *)) = ^(NSArray<NSIndexPath *> *indexPaths, UIView *(^viewProviderBlock)(NSIndexPath *)) {
        [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UIView *view = viewProviderBlock(obj);
            if (![view conformsToProtocol:@protocol(FVPlayerContainer)] && ![view conformsToProtocol:@protocol(FVContainerSupplier)]) {
                return;
            }
            if (self.viewVisibilityChecker(view)) {
                targetIndexPath = obj;
                targetView = view;
                *stop = YES;
            }
        }];
    };
       
    for (NSInteger idx = 0; idx < self.rootView.numberOfSections; idx++) {
        if (@available(iOS 9, *)) {
            // 先 header
            findTarget(visibleHeadersIndexPaths[@(idx)], ^UIView *(NSIndexPath *obj) {
                return [self.rootView supplementaryViewForElementKind:UICollectionElementKindSectionHeader atIndexPath:obj];
            });
            if (isFound()) { break; }
        }
        // 再 items
        findTarget(visibleItemsIndexPaths[@(idx)], ^UIView *(NSIndexPath *obj) {
            return [self.rootView cellForItemAtIndexPath:obj];
        });
        if (isFound()) { break; }
        if (@available(iOS 9, *)) {
            // 最后 footer
            findTarget(visibleFootersIndexPaths[@(idx)], ^UIView *(NSIndexPath *obj) {
                return [self.rootView supplementaryViewForElementKind:UICollectionElementKindSectionFooter atIndexPath:obj];
            });
        }
    }
    resultBlock(targetView, targetIndexPath);
}

- (NSIndexPath *)indexPathForContainer:(__kindof UIView *)container {
    if ([container isKindOfClass:[UICollectionViewCell class]]) {
        return [self.rootView indexPathForCell:container];
    }
    //TODO: footer & header
    return nil;
}

- (UIView *)containerAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [self.rootView cellForItemAtIndexPath:indexPath];
    if (![cell conformsToProtocol:@protocol(FVPlayerContainer)] && ![cell conformsToProtocol:@protocol(FVContainerSupplier)]) {
        return nil;
    }
    return cell;
}

- (void)makeIndexPathFocus:(NSIndexPath *)indexPath {
    if (indexPath.section >= self.rootView.numberOfSections || indexPath.row >= [self.rootView numberOfItemsInSection:indexPath.section]) {
        NSAssert(0, @"invalid parameter: %@", indexPath);
        return;
    }
    // 系统方法一旦设置 contentInsets 之后就不准了，自己算吧
    // [self.rootView scrollToItemAtIndexPath:indexPath atScrollPosition:self.focusPosition animated:self.focusAnimatable];
    
    UICollectionView *collectionView = self.rootView;
    [collectionView layoutIfNeeded];
    UICollectionViewLayoutAttributes *attributes = [collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath];
    if (!attributes) {
        NSAssert(0, @"invalid parameter: %@", indexPath);
        return;
    }
    
    const CGFloat collectionViewWidth = collectionView.bounds.size.width;
    const CGFloat collectionViewHeight = collectionView.bounds.size.height;
    const UIEdgeInsets contentInset = self.ignoreContentInsetsWhileMakingFocus ? UIEdgeInsetsZero : fv_collectionViewEdgeInsets(collectionView);
    
    CGPoint contentOffset = collectionView.contentOffset;
    // x
    if (self.focusPosition & UICollectionViewScrollPositionLeft) {
        contentOffset.x = CGRectGetMinX(attributes.frame) - contentInset.left;
    } else if (self.focusPosition & UICollectionViewScrollPositionRight) {
        contentOffset.x = CGRectGetMaxX(attributes.frame) - collectionViewWidth - contentInset.left;
    } else if (self.focusPosition & UICollectionViewScrollPositionCenteredHorizontally) {
        const CGFloat insets = (contentInset.left - contentInset.right) / 2.0;
        contentOffset.x = CGRectGetMidX(attributes.frame) - collectionViewWidth / 2.0 - insets;
    }
    const CGFloat maxOffsetX = collectionView.contentSize.width - collectionView.frame.size.width + contentInset.right;
    const CGFloat minOffsetX = -contentInset.left;
    contentOffset.x = MIN(contentOffset.x, maxOffsetX);
    contentOffset.x = MAX(contentOffset.x, minOffsetX);
    
    // y
    if (self.focusPosition & UICollectionViewScrollPositionTop) {
        contentOffset.y = CGRectGetMinY(attributes.frame) - contentInset.top;
    } else if (self.focusPosition & UICollectionViewScrollPositionBottom) {
        contentOffset.y = CGRectGetMaxY(attributes.frame) - collectionViewHeight;
    } else if (self.focusPosition & UICollectionViewScrollPositionCenteredVertically) {
        const CGFloat insets = (contentInset.top - contentInset.bottom) / 2.0;
        contentOffset.y = CGRectGetMidY(attributes.frame) - collectionViewHeight / 2.0 - insets;
    }
    const CGFloat maxOffsetY = collectionView.contentSize.height - collectionView.frame.size.height + contentInset.bottom;
    const CGFloat minOffsetY = -contentInset.top;
    contentOffset.y = MIN(contentOffset.y, maxOffsetY);
    contentOffset.y = MAX(contentOffset.y, minOffsetY);

    [collectionView setContentOffset:contentOffset animated:self.focusAnimatable];
}

- (NSArray<UIView *> *)visibleContainers {
    NSMutableArray *visibleContainers = [NSMutableArray array];
    [self.rootView.visibleCells enumerateObjectsUsingBlock:^(__kindof UICollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj conformsToProtocol:@protocol(FVPlayerContainer)] && ![obj conformsToProtocol:@protocol(FVContainerSupplier)]) {
            return;
        }
        [visibleContainers addObject:obj];
    }];
    if (@available(iOS 9, *)) {
        [[self.rootView visibleSupplementaryViewsOfKind:UICollectionElementKindSectionFooter] enumerateObjectsUsingBlock:^(UICollectionReusableView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![obj conformsToProtocol:@protocol(FVPlayerContainer)] && ![obj conformsToProtocol:@protocol(FVContainerSupplier)]) {
                return;
            }
            [visibleContainers addObject:obj];
        }];
        [[self.rootView visibleSupplementaryViewsOfKind:UICollectionElementKindSectionHeader] enumerateObjectsUsingBlock:^(UICollectionReusableView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![obj conformsToProtocol:@protocol(FVPlayerContainer)] && ![obj conformsToProtocol:@protocol(FVContainerSupplier)]) {
                return;
            }
            [visibleContainers addObject:obj];
        }];
    }
    return visibleContainers.copy;
}

@end
