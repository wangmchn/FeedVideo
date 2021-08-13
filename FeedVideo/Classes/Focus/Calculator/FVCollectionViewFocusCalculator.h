//
//  FVCollectionViewFocusCalculator.h
//  FeedVideo
//
//  Created by Mark on 2019/9/25.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVFocusCalculator.h"

NS_ASSUME_NONNULL_BEGIN

/// 查询 UICollectionView 当前聚焦视图的模块
/// @discussion 默认实现为遍历当前所有可见的 cell，寻找满足协议的视图
@interface FVCollectionViewFocusCalculator : FVFocusCalculator <UICollectionView *>
/// 默认为 ture
@property (nonatomic, assign) BOOL focusAnimatable;
@property (nonatomic, assign) UICollectionViewScrollPosition focusPosition;
/// 默认为 false, 是否在聚焦的时候无视掉 contentInsets
/// @discussion 默认在聚焦的时候会计算 contentInsets，根据当前设置的 insets 来计算置顶/居中/置底的位置，如果不需要在聚焦的时候考虑 insets，可设置为 YES
@property (nonatomic, assign) BOOL ignoreContentInsetsWhileMakingFocus;

@end

NS_ASSUME_NONNULL_END
