//
//  FVCollectionViewLayout.m
//  synopsis
//
//  Created by Mark on 2018/3/13.
//  Copyright © 2018年 ghostjiang. All rights reserved.
//

#import "FVCollectionViewLayout.h"

@implementation FVCollectionViewLayout {
    CGFloat _itemW;
    CGFloat _viewW;
    CGFloat _realSpacing;
}

- (instancetype)init {
    if (self = [super init]) {
        self.scale = 0.9;
        self.visibleCount = 3;
    }
    return self;
}

- (void)prepareLayout {
    [super prepareLayout];
    _viewW = CGRectGetWidth(self.collectionView.frame);
    _itemW = self.itemSize.width;
    _realSpacing = self.itemSpacing - _itemW * (1 - self.scale) / 2.0;
}

- (CGSize)collectionViewContentSize {
    if ([self.collectionView numberOfSections] != 1) {
        return CGSizeZero;
    }
    NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:0];
    CGFloat width = self.insets.left + self.insets.right + (_itemW + _realSpacing) * numberOfItems - _realSpacing;
    return CGSizeMake(width, 0);
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSInteger cellCount = [self.collectionView numberOfItemsInSection:0];
    CGFloat centerX = self.collectionView.contentOffset.x + _viewW / 2;
    NSInteger index = centerX / (_itemW + _realSpacing);
    NSInteger count = (self.visibleCount - 1) / 2;
    NSInteger minIndex = MAX(0, (index - count));
    NSInteger maxIndex = MIN((cellCount - 1), (index + count));
    NSMutableArray *array = [NSMutableArray array];
    for (NSInteger i = minIndex; i <= maxIndex; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
        [array addObject:attributes];
    }
    return array;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat centerX = self.collectionView.contentOffset.x + self.collectionView.frame.size.width / 2;
    UICollectionViewLayoutAttributes *curAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    curAttributes.frame = ({
        CGRect frame = CGRectZero;
        frame.origin.x = self.insets.left + curAttributes.indexPath.row * (_itemW + _realSpacing);
        frame.origin.y = self.topSpacing;
        frame.size = self.itemSize;
        frame;
    });
    
    CGFloat delta = ABS(curAttributes.center.x - centerX);
    
    CGFloat dis = (_itemW + _realSpacing) / (1 - self.scale);
    CGFloat scale = 1 - delta / dis;
    curAttributes.transform = CGAffineTransformMakeScale(scale, scale);
    
    return curAttributes;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity {
    CGFloat itemSize = _itemW + _realSpacing;
    CGFloat rawPage = self.collectionView.contentOffset.x / itemSize;
    NSInteger targetPage = 0;
    if (fabs(velocity.x) < 0.3) {
        // 速度很小，要么反弹，要么直接滚动到指定页数
        targetPage = round(rawPage);
    } else {
        // 不反弹，直接滚动到指定页数
        NSInteger currentPage = 0;
        if (velocity.x > 0.0) {
            // 下一页
            currentPage = floor(rawPage);
            targetPage = currentPage + 1;
        } else {
            // 上一页
            currentPage = ceil(rawPage);
            targetPage = currentPage - 1;
        }
    }
    CGPoint targetContentOffset = proposedContentOffset;
    targetContentOffset.x = targetPage * itemSize;
    return targetContentOffset;
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
    UICollectionViewLayoutAttributes *attrs = [self layoutAttributesForItemAtIndexPath:itemIndexPath].copy;
    attrs.alpha = 0;
    // attrs.transform = CGAffineTransformMakeTranslation(0, -attrs.frame.size.height / 2.0);
    attrs.transform = CGAffineTransformMakeTranslation(-attrs.frame.size.width / 2.0, 0);
    return attrs;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return !CGRectEqualToRect(newBounds, self.collectionView.bounds);
}

@end
