//
//  FVPreloadManager.h
//  VideoFeedsPlay
//
//  Created by 王敏 on 2019/10/11.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@import FeedVideo;

NS_ASSUME_NONNULL_BEGIN

@interface FVPreloadManager : NSObject <FVPreloadMgrProtocol>
+ (instancetype)shareInstance;
@end

NS_ASSUME_NONNULL_END
