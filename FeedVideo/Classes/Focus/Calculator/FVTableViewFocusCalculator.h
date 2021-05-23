//
//  FVTableViewFocusCalculator.h
//  FeedVideo
//
//  Created by Mark on 2019/9/25.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVFocusCalculator.h"

NS_ASSUME_NONNULL_BEGIN

/**
 查询 UITableView 当前聚焦视图的模块
 @discussion 默认实现为遍历当前所有可见的 cell，寻找满足协议的视图
 */
@interface FVTableViewFocusCalculator : FVFocusCalculator <UITableView *>
/// 默认为 ture
@property (nonatomic, assign) BOOL focusAnimatable;
@property (nonatomic, assign) UITableViewScrollPosition focusPosition;
@end

NS_ASSUME_NONNULL_END
