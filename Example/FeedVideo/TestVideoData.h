//
//  TestVideoData.h
//  FeedVideo
//
//  Created by 王敏 on 2019/10/10.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TestVideoData : NSObject

+ (instancetype)shareInstance;

// NSString or NSArray
- (NSArray *)buildNestingDemoVidList;

- (NSArray<NSString *> *)buildTikTokVidListWithInitialVid:(NSString *)vid;

@end

NS_ASSUME_NONNULL_END
