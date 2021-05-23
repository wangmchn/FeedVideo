//
//  UIScrollView+FVMultipleDelegates.m
//  FeedVideo
//
//  Created by Mark on 2019/9/27.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "UIScrollView+FVMultipleDelegates.h"
#import "FVMultipleDelegates.h"
#import "FVWeakReference.h"
#import <objc/runtime.h>
#import "NSObject+FVSwizzle.h"

@implementation UIScrollView (FVMultipleDelegates)

- (void)fv_setMultipleDelegates:(FVMultipleDelegates *)delegates {
    objc_setAssociatedObject(self, @selector(fv_multipleDelegates), delegates, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (FVMultipleDelegates *)fv_multipleDelegates {
    FVMultipleDelegates *multipleDelegates = objc_getAssociatedObject(self, @selector(fv_multipleDelegates));
    if (!multipleDelegates) {
        multipleDelegates = [FVMultipleDelegates alloc];
        [self fv_setMultipleDelegates:multipleDelegates];
    }
    return multipleDelegates;
}

- (void)fv_setLastDelegate:(id<UIScrollViewDelegate>)delegate {
    FVWeakReference *weakRef = objc_getAssociatedObject(self, @selector(fv_lastDelegate));
    if (!weakRef) {
        weakRef = [FVWeakReference new];
    }
    weakRef.object = delegate;
    objc_setAssociatedObject(self, @selector(fv_lastDelegate), weakRef, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<UIScrollViewDelegate>)fv_lastDelegate {
    FVWeakReference *weakRef = objc_getAssociatedObject(self, @selector(fv_lastDelegate));
    return weakRef.object;
}

- (void)fv_updateCacheOfDelegateSelectors {
    if (!self.fv_start) {
        return;
    }
    // scrollView 内部会缓存是否 responseToSelector:，通过 reset 来重置缓存。
    [self fv_origin_setDelegate:nil];
    [self fv_origin_setDelegate:[self fv_multipleDelegates]];
}

#pragma mark - Hook
- (void)fv_hook_setDelegate:(id<UIScrollViewDelegate>)delegate {
    if (!self.fv_start) {
        [self fv_origin_setDelegate:delegate];
    } else {
        if (delegate != [self fv_multipleDelegates]) {
            [self fv_multipleDelegates].mainTarget = delegate;
        }
        [self fv_updateCacheOfDelegateSelectors];
    }
    [self fv_setLastDelegate:delegate];
}

- (void)fv_origin_setDelegate:(id<UIScrollViewDelegate>)delegate {
    NSAssert(0, @"subclass must override this method!");
}

#pragma mark - Public
- (void)fv_addDelegate:(id<UIScrollViewDelegate>)delegate {
    [self.fv_multipleDelegates addDelegate:delegate];
    [self fv_updateCacheOfDelegateSelectors];
}

- (void)fv_removeDelegate:(id<UIScrollViewDelegate>)delegate {
    [self.fv_multipleDelegates removeDelegate:delegate];
    [self fv_updateCacheOfDelegateSelectors];
}

- (BOOL)fv_containsDelegate:(id<UIScrollViewDelegate>)delegate {
    return [self.fv_multipleDelegates containsDelegate:delegate];
}

- (void)fv_setStart:(BOOL)fv_start {
    BOOL start = self.fv_start;
    if (start == fv_start) {
        return;
    }
    objc_setAssociatedObject(self, @selector(fv_start), @(fv_start), OBJC_ASSOCIATION_COPY_NONATOMIC);
    if (fv_start) {
        if (self.delegate != [self fv_multipleDelegates]) {
            [self fv_multipleDelegates].mainTarget = self.delegate;
        }
        [self fv_updateCacheOfDelegateSelectors];
    } else {
        [self fv_origin_setDelegate:[self fv_lastDelegate]];
    }
}

- (BOOL)fv_start {
    return [objc_getAssociatedObject(self, @selector(fv_start)) boolValue];
}

@end

/*>------------------------------------------------------------------------------------------------------------------------------------<*/
// 这里为什么要分开 hook delegate 呢，理论上只有 hook [UIScrollView -setDelegate:] 就可以了
// 但是 UIKit 在 UIScrollView / UITableView / UICollectionView -setDelegate: 的时候，就会把 response 的方法缓存下来
// 当我们增加多代理监听者时，我们需要通过调用原始方法 -setDelegate:nil / -setDelegate:delegate 来更新缓存
// 当我们只调用到 [UIScrollView -setDelegate:] 时，只能更新到 UIScrollView 层面的缓存。因而我们需要分别 hook 子类层面的接口
/*>------------------------------------------------------------------------------------------------------------------------------------<*/

@interface UITableView (MultipleDelegates)

@end

@implementation UITableView (MultipleDelegates)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self fv_swizzleInstanceMethod:@selector(setDelegate:) with:@selector(fv_tableview_setDelegate:)];
    });
}

- (void)fv_tableview_setDelegate:(id<UITableViewDelegate>)delegate {
    [self fv_hook_setDelegate:delegate];
}

- (void)fv_origin_setDelegate:(__kindof id<UIScrollViewDelegate>)delegate {
    [self fv_tableview_setDelegate:delegate];
}

@end

@interface UICollectionView (MultipleDelegates)

@end

@implementation UICollectionView (MultipleDelegates)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self fv_swizzleInstanceMethod:@selector(setDelegate:) with:@selector(fv_collectionview_setDelegate:)];
    });
}

- (void)fv_collectionview_setDelegate:(id<UICollectionViewDelegate>)delegate {
    [self fv_hook_setDelegate:delegate];
}

- (void)fv_origin_setDelegate:(__kindof id<UIScrollViewDelegate>)delegate {
    [self fv_collectionview_setDelegate:delegate];
}

@end
