//
//  FVRunLoopObserver.h
//  FeedVideo
//
//  Created by Mark on 2019/10/3.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define FVCalculationOrder LONG_MAX - 100

@interface FVRunLoopObserver : NSObject

- (instancetype)initWithActivity:(CFRunLoopActivity)activity order:(CFIndex)order mode:(CFRunLoopMode)mode NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)observeWithKey:(NSString *)key repeats:(BOOL)repeats usingBlock:(void (^)(CFRunLoopObserverRef observer, CFRunLoopActivity activity))block;

@end

NS_ASSUME_NONNULL_END
