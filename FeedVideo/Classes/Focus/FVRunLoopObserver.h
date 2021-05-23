//
//  FVRunLoopObserver.h
//  FeedVideo
//
//  Created by Mark on 2019/10/3.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define VFPCalculationOrder LONG_MAX - 100

static inline void fv_invalid_observer(CFRunLoopObserverRef observer) {
    if (CFRunLoopObserverIsValid(observer)) {
        CFRunLoopObserverInvalidate(observer);
    }
}

static inline void fv_main_remove_observer(CFRunLoopObserverRef observer, CFRunLoopMode mode) {
    if (CFRunLoopContainsObserver([[NSRunLoop mainRunLoop] getCFRunLoop], observer, mode)) {
        CFRunLoopRemoveObserver([[NSRunLoop mainRunLoop] getCFRunLoop], observer, mode);
    }
}

static inline void fv_main_add_observer(CFRunLoopObserverRef observer, CFRunLoopMode mode) {
    fv_main_remove_observer(observer, mode);
    CFRunLoopAddObserver([[NSRunLoop mainRunLoop] getCFRunLoop], observer, mode);
}

@interface FVRunLoopObserver : NSObject

- (instancetype)initWithActivity:(CFRunLoopActivity)activity order:(CFIndex)order mode:(CFRunLoopMode)mode NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)observeWithKey:(NSString *)key repeats:(BOOL)repeats usingBlock:(void (^)(CFRunLoopObserverRef observer, CFRunLoopActivity activity))block;

@end

NS_ASSUME_NONNULL_END
