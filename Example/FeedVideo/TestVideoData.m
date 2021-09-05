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
            @"coldlikeadog.mp4",
            @"helicopter.mp4",
            @"idleruby.mp4",
            @"kangaroo.mp4",
            @"miao.mp4",
            @"sunshine.mp4",
            @"swim.mp4",
            @"taigu.mp4",
            @"tina.mp4"
        ];
    }
    return self;
}

- (NSArray *)buildNestingDemoVidList {
    NSMutableArray *result = [NSMutableArray array];
    for (int i = 0; i < 10; i++) {
        [result addObject:self.testVideoInfoArray.copy];
        [result addObjectsFromArray:self.testVideoInfoArray];
    }
    return result;
}

- (NSArray<NSString *> *)buildTikTokVidListWithInitialVid:(NSString *)vid {
    NSMutableArray *result = self.testVideoInfoArray.mutableCopy;
    [result removeObject:vid];
    [result insertObject:vid atIndex:0];
    for (int i = 0; i < 9; i++) {
        [result addObjectsFromArray:self.testVideoInfoArray];
    }
    return result;
}

@end
