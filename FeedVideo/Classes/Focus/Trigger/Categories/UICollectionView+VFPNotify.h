//
//  UICollectionView+VFPNotify.h
//  FeedVideo
//
//  Created by Mark on 2019/10/2.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FVCollectionViewNotifyDelegate <NSObject>
@optional

- (void)fv_collectionViewDidUpdateData:(UICollectionView *)collectionView;
- (void)fv_collectionView:(UICollectionView *)collectionView scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated;
- (void)fv_collectionView:(UICollectionView *)collectionView setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;

@end

@interface UICollectionView (VFPNotify)
@property (nonatomic, weak, setter=fv_setNotifyDelegate:) id<FVCollectionViewNotifyDelegate> fv_notifyDelegate;
@end

NS_ASSUME_NONNULL_END
