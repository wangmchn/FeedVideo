//
//  UICollectionView+FVNotify.m
//  FeedVideo
//
//  Created by Mark on 2019/10/2.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "UICollectionView+FVNotify.h"
#import "NSObject+FVSwizzle.h"
#import <objc/runtime.h>
#import "FVWeakReference.h"

/*
 // These methods allow dynamic modification of the current set of items in the collection view
 - (void)insertSections:(NSIndexSet *)sections;
 - (void)deleteSections:(NSIndexSet *)sections;
 - (void)reloadSections:(NSIndexSet *)sections;
 - (void)moveSection:(NSInteger)section toSection:(NSInteger)newSection;
 
 - (void)insertItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;
 - (void)deleteItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;
 - (void)reloadItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;
 - (void)moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath;
 */
@implementation UICollectionView (FVNotify)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self fv_swizzleInstanceMethod:@selector(reloadData) with:@selector(fv_reloadData)];
        [self fv_swizzleInstanceMethod:@selector(scrollToItemAtIndexPath:atScrollPosition:animated:) with:@selector(fv_scrollToItemAtIndexPath:atScrollPosition:animated:)];
        [self fv_swizzleInstanceMethod:@selector(performBatchUpdates:completion:) with:@selector(fv_performBatchUpdates:completion:)];
        [self fv_swizzleInstanceMethod:@selector(setContentOffset:animated:) with:@selector(fv_setContentOffset:animated:)];
    });
}

- (void)fv_setNotifyDelegate:(id<FVCollectionViewNotifyDelegate>)fv_notifyDelegate {
    FVWeakReference *reference = [FVWeakReference new];
    reference.object = fv_notifyDelegate;
    objc_setAssociatedObject(self, @selector(fv_notifyDelegate), reference, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<FVCollectionViewNotifyDelegate>)fv_notifyDelegate {
    FVWeakReference *reference = objc_getAssociatedObject(self, @selector(fv_notifyDelegate));
    return reference.object;
}

#pragma mark - Hook
- (void)fv_reloadData {
    [self fv_reloadData];
    
    if ([self.fv_notifyDelegate respondsToSelector:@selector(fv_collectionViewDidUpdateData:)]) {
        [self.fv_notifyDelegate fv_collectionViewDidUpdateData:self];
    }
}

- (void)fv_scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated {
    [self fv_scrollToItemAtIndexPath:indexPath atScrollPosition:scrollPosition animated:animated];
    
    if ([self.fv_notifyDelegate respondsToSelector:@selector(fv_collectionView:scrollToItemAtIndexPath:atScrollPosition:animated:)]) {
        [self.fv_notifyDelegate fv_collectionView:self scrollToItemAtIndexPath:indexPath atScrollPosition:scrollPosition animated:animated];
    }
}

- (void)fv_setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {
    [self fv_setContentOffset:contentOffset animated:animated];
    
    if ([self.fv_notifyDelegate respondsToSelector:@selector(fv_collectionView:setContentOffset:animated:)]) {
        [self.fv_notifyDelegate fv_collectionView:self setContentOffset:contentOffset animated:animated];
    }
}

- (void)fv_performBatchUpdates:(void (^)(void))updates completion:(void (^)(BOOL))completion {
    __weak typeof(self) weak_self = self;
    [self fv_performBatchUpdates:updates completion:^(BOOL finished) {
        !completion ?: completion(finished);
        __strong typeof(weak_self) strong_self = weak_self;
        if (finished && [strong_self.fv_notifyDelegate respondsToSelector:@selector(fv_collectionViewDidUpdateData:)]) {
            [strong_self.fv_notifyDelegate fv_collectionViewDidUpdateData:strong_self];
        }
    }];
}

@end
