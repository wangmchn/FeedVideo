//
//  FVRunLoopObserver.m
//  FeedVideo
//
//  Created by Mark on 2019/10/3.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVRunLoopObserver.h"

NS_INLINE void FVInvalidObserver(CFRunLoopObserverRef observer) {
    if (CFRunLoopObserverIsValid(observer)) {
        CFRunLoopObserverInvalidate(observer);
    }
}

NS_INLINE void FVRemoveObserverInMain(CFRunLoopObserverRef observer, CFRunLoopMode mode) {
    if (CFRunLoopContainsObserver([[NSRunLoop mainRunLoop] getCFRunLoop], observer, mode)) {
        CFRunLoopRemoveObserver([[NSRunLoop mainRunLoop] getCFRunLoop], observer, mode);
    }
}

NS_INLINE void FVAddObserverInMain(CFRunLoopObserverRef observer, CFRunLoopMode mode) {
    FVRemoveObserverInMain(observer, mode);
    CFRunLoopAddObserver([[NSRunLoop mainRunLoop] getCFRunLoop], observer, mode);
}

@interface _FVRunLoopTask : NSObject
@property (nonatomic, copy) void (^block)(CFRunLoopObserverRef, CFRunLoopActivity);
@property (nonatomic, copy) NSString *key;

@property (nonatomic, assign) BOOL repeats;
@end

@implementation _FVRunLoopTask

- (BOOL)isEqual:(id)object {
    if ([super isEqual:object]) {
        return YES;
    }
    if ([object isKindOfClass:self.class] && [[(_FVRunLoopTask *)object key] isEqualToString:self.key]) {
        return YES;
    }
    return NO;
}

- (NSUInteger)hash {
    return self.key.hash;
}

@end

@interface FVRunLoopObserver ()
@property (nonatomic, strong) NSMutableArray<_FVRunLoopTask *> *tasks;
@property (nonatomic, strong) NSString *mode;
@end

@implementation FVRunLoopObserver {
    CFRunLoopObserverRef _runloopObserver;
}

- (instancetype)initWithActivity:(CFRunLoopActivity)activity order:(CFIndex)order mode:(CFRunLoopMode)mode {
    self = [super init];
    if (self) {
        _tasks = [NSMutableArray array];
        __weak typeof(self) weak_self = self;
        _mode = (__bridge NSString *)mode;
        _runloopObserver = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, activity, YES, order, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
            if (!weak_self) {
                return;
            }
            __strong typeof(weak_self) strong_self = weak_self;
            NSArray<_FVRunLoopTask *> *tasks = strong_self.tasks.copy;
            NSMutableArray<_FVRunLoopTask *> *invalidTasks = [NSMutableArray array];
            [tasks enumerateObjectsUsingBlock:^(_FVRunLoopTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.block(observer, activity);
                if (!obj.repeats) {
                    [invalidTasks addObject:obj];
                }
            }];
            [strong_self.tasks removeObjectsInArray:invalidTasks];
            if (strong_self && !strong_self.tasks.count) {
                FVRemoveObserverInMain(strong_self->_runloopObserver, (__bridge CFStringRef)strong_self.mode);
            }
        });
    }
    return self;
}

- (void)observeWithKey:(NSString *)key repeats:(BOOL)repeats usingBlock:(void (^)(CFRunLoopObserverRef, CFRunLoopActivity))block {
    [self removeTaskForKey:key];
    _FVRunLoopTask *task = [_FVRunLoopTask new];
    task.repeats = repeats;
    task.block = block;
    task.key = key;
    if (!self.tasks.count) {
        FVAddObserverInMain(_runloopObserver, (__bridge CFStringRef)self.mode);
    }
    [self.tasks addObject:task];
}

- (void)removeTaskForKey:(NSString *)key {
    __block _FVRunLoopTask *task = nil;
    [self.tasks enumerateObjectsUsingBlock:^(_FVRunLoopTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.key isEqualToString:key]) {
            task = obj;
            *stop = YES;
        }
    }];
    if (task) {
        [self.tasks removeObject:task];
    }
}

- (void)dealloc {
    FVRemoveObserverInMain(_runloopObserver, (__bridge CFStringRef)self.mode);
    FVInvalidObserver(_runloopObserver);
    CFRelease(_runloopObserver);
    _runloopObserver = nil;
}

@end
