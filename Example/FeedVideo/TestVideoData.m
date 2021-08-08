//
//  TestVideoData.m
//  FeedVideo
//
//  Created by 王敏 on 2019/10/10.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "TestVideoData.h"

@interface TestVideoData ()
@property (nonatomic, strong) NSArray *testVideoInfoArray;
@end

@implementation TestVideoData

+ (instancetype)shareInstance {
    static TestVideoData *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TestVideoData alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.testVideoInfoArray = @[
            @"https://v-cdn.zjol.com.cn/280443.mp4",
            @"https://v-cdn.zjol.com.cn/276982.mp4",
            @"https://v-cdn.zjol.com.cn/276984.mp4",
            @"https://v-cdn.zjol.com.cn/276985.mp4",
            @"https://v-cdn.zjol.com.cn/277004.mp4",
        ];
    }
    return self;
}

- (NSString *)randomURL {
    if (self.testVideoInfoArray.count < 0) {
        return nil;
    }
    NSInteger random = arc4random() % (self.testVideoInfoArray.count);
    if (random >= 0 && random < self.testVideoInfoArray.count) {
        return [self.testVideoInfoArray objectAtIndex:random];
    }
    return nil;
}

@end
