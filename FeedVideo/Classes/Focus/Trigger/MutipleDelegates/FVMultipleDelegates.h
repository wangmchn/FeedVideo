//
//  FVMultipleDelegates.h
//  FeedVideo
//
//  Created by Mark on 2019/9/27.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// FVMultipleDelegates 是用来实现将单一事件转发给多个模块的功能的组件
/// @discussion 它只是单纯的通过 forwardInvocation: 转发事件给对应的实现者
@interface FVMultipleDelegates : NSObject <UIScrollViewDelegate, UICollectionViewDelegate, UITableViewDelegate>
@property (nonatomic, weak) id mainTarget;

/// 添加一个代理
- (void)addDelegate:(id)delegate;

/// 移除一个代理
- (void)removeDelegate:(id)delegate;

/// 判断当前是否包含某个代理
- (BOOL)containsDelegate:(id)aDelegate;

@end

NS_ASSUME_NONNULL_END
