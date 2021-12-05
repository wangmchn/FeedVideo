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
@property (nonatomic, assign) BOOL isAnimating;
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

- (void)fv_collectionView:(UICollectionView *)collectionView scrollRectToVisible:(CGRect)rect animated:(BOOL)animated {
    // 这里只需要增对无动画的去响应就可以了，因为 animated 会触发 -scrollViewDidEndScrollingAnimation: 回调
    CGRect visibleRect = CGRectMake(collectionView.contentOffset.x,
                                    collectionView.contentOffset.y,
                                    collectionView.bounds.size.width,
                                    collectionView.bounds.size.height);
    if (!animated || CGRectContainsRect(visibleRect, rect)) {
        [self trigger];
    } else {
        self.isAnimating = YES;
    }
}

- (void)fv_collectionView:(UICollectionView *)collectionView setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {
    // 这里只需要增对无动画的去响应就可以了，因为 animated 会触发 -scrollViewDidEndScrollingAnimation: 回调
    // 或者 contentOffset 相等
    if (!animated || VFPPointEqualToPoint(contentOffset, collectionView.contentOffset)) {
        [collectionView layoutIfNeeded];
        [self trigger];
    } else {
        self.isAnimating = YES;
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

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    self.isAnimating = NO;
    /// super 调用了 -trigger，所以先设置 NO
    [super scrollViewDidEndScrollingAnimation:scrollView];
}

- (void)trigger {
    // 如过滚动动画过程中
    if (self.isAnimating) {
        return;
    }
    [super trigger];
}

@end
