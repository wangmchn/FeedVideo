//
//  FVContinueHandler.h
//  FeedVideo
//
//  Created by Mark on 2019/9/25.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FVFocusMonitor.h"
#import "FVPlayerProtocol.h"
@class FVContinueHandler;
@class FVFeedVideoManager;

NS_ASSUME_NONNULL_BEGIN

/// 自动续播模块
@interface FVContinueHandler : NSObject
/// 提供尾部的 monitor，从尾部开始遍历续播，即当页面嵌套多个列表时，优先续播子列表
@property (nonatomic, copy) FVFocusMonitor *(^tailMonitorProvider)(void);

- (void)trigger:(id<FVPlayerProtocol>)sender;
- (void)cancelContinue;

@end

NS_ASSUME_NONNULL_END
