//
//  UITableView+FVNotify.m
//  FeedVideo
//
//  Created by Mark on 2019/10/2.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "UITableView+FVNotify.h"
#import "NSObject+FVSwizzle.h"
#import <objc/runtime.h>
#import "FVWeakReference.h"

/*
- (void)endUpdates;

- (void)insertSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation;
- (void)deleteSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation;
- (void)reloadSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation NS_AVAILABLE_IOS(3_0);
- (void)moveSection:(NSInteger)section toSection:(NSInteger)newSection NS_AVAILABLE_IOS(5_0);

- (void)insertRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation;
- (void)deleteRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation;
- (void)reloadRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation NS_AVAILABLE_IOS(3_0);
- (void)moveRowAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath NS_AVAILABLE_IOS(5_0);
*/
@implementation UITableView (FVNotify)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self fv_swizzleInstanceMethod:@selector(reloadData) with:@selector(fv_reloadData)];
        [self fv_swizzleInstanceMethod:@selector(scrollRectToVisible:animated:) with:@selector(fv_scrollRectToVisible:animated:)];
        [self fv_swizzleInstanceMethod:@selector(setContentOffset:animated:) with:@selector(fv_setContentOffset:animated:)];
        if (@available(iOS 11, *)) {
            [self fv_swizzleInstanceMethod:@selector(performBatchUpdates:completion:) with:@selector(fv_performBatchUpdates:completion:)];
        }
    });
}

- (void)fv_setNotifyDelegate:(id<VFPTableViewNotifyDelegate>)fv_notifyDelegate {
    FVWeakReference *reference = [FVWeakReference new];
    reference.object = fv_notifyDelegate;
    objc_setAssociatedObject(self, @selector(fv_notifyDelegate), reference, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<VFPTableViewNotifyDelegate>)fv_notifyDelegate {
    FVWeakReference *reference = objc_getAssociatedObject(self, @selector(fv_notifyDelegate));
    return reference.object;
}

#pragma mark - Hook
- (void)fv_reloadData {
    [self fv_reloadData];
    
    if ([self.fv_notifyDelegate respondsToSelector:@selector(fv_tableViewDidUpdateData:)]) {
        [self.fv_notifyDelegate fv_tableViewDidUpdateData:self];
    }
}

- (void)fv_performBatchUpdates:(void (^)(void))updates completion:(void (^)(BOOL))completion {
    __weak typeof(self) weak_self = self;
    [self fv_performBatchUpdates:updates completion:^(BOOL finished) {
        !completion ?: completion(finished);
        __strong typeof(weak_self) strong_self = weak_self;
        if (finished && [strong_self.fv_notifyDelegate respondsToSelector:@selector(fv_tableViewDidUpdateData:)]) {
            [strong_self.fv_notifyDelegate fv_tableViewDidUpdateData:strong_self];
        }
    }];
}

- (void)fv_setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {
    [self fv_setContentOffset:contentOffset animated:animated];
    
    if ([self.fv_notifyDelegate respondsToSelector:@selector(fv_tableview:setContentOffset:animated:)]) {
        [self.fv_notifyDelegate fv_tableview:self setContentOffset:contentOffset animated:animated];
    }
}

- (void)fv_scrollRectToVisible:(CGRect)rect animated:(BOOL)animated {
    [self fv_scrollRectToVisible:rect animated:animated];
    
    if ([self.fv_notifyDelegate respondsToSelector:@selector(fv_tableview:scrollRectToVisible:animated:)]) {
        [self.fv_notifyDelegate fv_tableview:self scrollRectToVisible:rect animated:animated];
    }
}

@end
