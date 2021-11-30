//
//  FVCollectionViewFocusTrigger.m
//  FeedVideo
//
//  Created by Mark on 2019/9/26.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVCollectionViewFocusTrigger.h"
#import "UIScrollView+FVMultipleDelegates.h"
#import "UICollectionView+FVNotify.h"

@interface FVCollectionViewFocusTrigger () <UICollectionViewDelegate, FVCollectionViewNotifyDelegate>

@end

@implementation FVCollectionViewFocusTrigger

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView {
    self = [super init];
    if (self) {
        _collectionView = collectionView;
        [self start];
    }
    return self;
}

- (void)start {
    [super start];
    [self.collectionView fv_setStart:YES];
    [self.collectionView fv_addDelegate:self];
    [self.collectionView fv_setNotifyDelegate:self];
}

- (void)stop {
    [super stop];
    [self.collectionView fv_setStart:NO];
    [self.collectionView fv_removeDelegate:self];
    [self.collectionView fv_setNotifyDelegate:nil];
}

#pragma mark - FVCollectionViewNotifyDelegate
- (void)fv_collectionViewDidUpdateData:(UICollectionView *)collectionView {
    [self trigger];
}

- (void)fv_collectionView:(UICollectionView *)collectionView scrollToItemAtIndexPath:(nonnull NSIndexPath *)indexPath atScrollPosition:(UICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated {
    // 这里只需要增对无动画的去响应就可以了，因为 animated 会触发 -scrollViewDidEndScrollingAnimation: 回调
    if (!animated) {
        [self trigger];
    } else {
        // FIXME: 更准确的判断方式
        CGPoint contentOffset = collectionView.contentOffset;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (VFPPointEqualToPoint(contentOffset, collectionView.contentOffset)) {
                // 有动画可能没发生滚动，不会触发回调，这里间隔 0.1s 检查下 contentOffset 吧
                [collectionView layoutIfNeeded];
                [self trigger];
            }
        });
    }
}

- (void)fv_collectionView:(UICollectionView *)collectionView setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {
    // 这里只需要增对无动画的去响应就可以了，因为 animated 会触发 -scrollViewDidEndScrollingAnimation: 回调
    // 或者 contentOffset 相等
    if (!animated || VFPPointEqualToPoint(contentOffset, collectionView.contentOffset)) {
        [collectionView layoutIfNeeded];
        [self trigger];
    }
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate trigger:self viewWillDisplay:cell indexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate trigger:self viewDidEndDisplaying:cell indexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplaySupplementaryView:(UICollectionReusableView *)view forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    [self.delegate trigger:self viewWillDisplay:view indexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    [self.delegate trigger:self viewDidEndDisplaying:view indexPath:indexPath];
}

@end
