//
//  UIScrollView+FVMultipleDelegates.h
//  FeedVideo
//
//  Created by Mark on 2019/9/27.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIScrollView (FVMultipleDelegates)

/// 开始多代理模式，安全起见，只有在调用该方法后，才能开始
@property (nonatomic, assign, setter=fv_setStart:) BOOL fv_start;

/// 添加一个代理
- (void)fv_addDelegate:(id<UIScrollViewDelegate>)delegate;

/// 移除一个代理
- (void)fv_removeDelegate:(id<UIScrollViewDelegate>)delegate;

/// 判断是否包含代理
- (BOOL)fv_containsDelegate:(id<UIScrollViewDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
