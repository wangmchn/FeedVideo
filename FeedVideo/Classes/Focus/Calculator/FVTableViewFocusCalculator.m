//
//  FVTableViewFocusCalculator.m
//  FeedVideo
//
//  Created by Mark on 2019/9/25.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVTableViewFocusCalculator.h"

@implementation FVTableViewFocusCalculator

- (instancetype)initWithRootView:(__kindof UIView *)rootView {
    self = [super initWithRootView:rootView];
    if (self) {
        _focusAnimatable = YES;
        _focusPosition = UITableViewScrollPositionMiddle;
    }
    return self;
}

- (void)findTargetContainerWithKey:(NSString *)key usingBlock:(void (^)(__kindof UIView * _Nullable, NSIndexPath * _Nullable))resultBlock {
    if (!self.rootView.window) {
        resultBlock(nil, nil);
        return;
    }
    NSArray<__kindof UITableViewCell *> *sortedVisibleCells = [self.rootView.visibleCells sortedArrayUsingComparator:^NSComparisonResult(UICollectionViewCell * _Nonnull obj1, UICollectionViewCell * _Nonnull obj2) {
        return CGRectGetMinY(obj1.frame) > CGRectGetMinY(obj2.frame);
    }];
    __block UITableViewCell *firstChoice = nil;
    [sortedVisibleCells enumerateObjectsUsingBlock:^(__kindof UITableViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj conformsToProtocol:@protocol(FVPlayerContainer)] && ![obj conformsToProtocol:@protocol(FVContainerSupplier)]) {
            return;
        }
        BOOL isViewVisible = self.viewVisibilityChecker(obj);
        if (isViewVisible) {
            firstChoice = obj;
            *stop = YES;
        }
    }];
    if (firstChoice) {
        NSIndexPath *indexPath = [self.rootView indexPathForCell:firstChoice];
        resultBlock(firstChoice, indexPath);
    } else {
        resultBlock(nil, nil);
    }
}

- (NSIndexPath *)indexPathForContainer:(__kindof UIView *)container {
    if (![container isKindOfClass:[UITableViewCell class]]) {
        NSParameterAssert([container isKindOfClass:[UITableViewCell class]]);
        return nil;
    }
    return [self.rootView indexPathForCell:(UITableViewCell *)container];
}

- (UIView *)containerAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.rootView cellForRowAtIndexPath:indexPath];
    if (![cell conformsToProtocol:@protocol(FVPlayerContainer)] && ![cell conformsToProtocol:@protocol(FVContainerSupplier)]) {
        return nil;
    }
    return cell;
}

- (void)makeIndexPathFocus:(NSIndexPath *)indexPath {
    if (indexPath.section >= self.rootView.numberOfSections || indexPath.row >= [self.rootView numberOfRowsInSection:indexPath.section]) {
        NSAssert(0, @"invalid parameter: %@", indexPath);
        return;
    }
    [self.rootView scrollToRowAtIndexPath:indexPath atScrollPosition:self.focusPosition animated:self.focusAnimatable];
}

- (NSArray<UIView *> *)visibleContainers {
    NSMutableArray *visibleContainers = [NSMutableArray array];
    [self.rootView.visibleCells enumerateObjectsUsingBlock:^(__kindof UITableViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj conformsToProtocol:@protocol(FVPlayerContainer)] && ![obj conformsToProtocol:@protocol(FVContainerSupplier)]) {
            return;
        }
        [visibleContainers addObject:obj];
    }];
    return visibleContainers.copy;
}

@end
