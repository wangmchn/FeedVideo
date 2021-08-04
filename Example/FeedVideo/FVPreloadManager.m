//
//  FVPreloadManager.m
//  VideoFeedsPlay
//
//  Created by 王敏 on 2019/10/11.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVPreloadManager.h"

@implementation FVPreloadManager

+ (instancetype)shareInstance {
    static FVPreloadManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FVPreloadManager alloc] init];
    });
    return instance;
}

- (void)fv_preloadVideoDataList:(NSArray *)videoDataList {
    /// preload if needed
}

@end
