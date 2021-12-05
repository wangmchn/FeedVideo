//
//  FVTableViewFocusTrigger.m
//  FeedVideo
//
//  Created by Mark on 2019/9/26.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVTableViewFocusTrigger.h"
#import "UIScrollView+FVMultipleDelegates.h"
#import "UITableView+FVNotify.h"

@interface FVTableViewFocusTrigger () <UITableViewDelegate, VFPTableViewNotifyDelegate>
@property (nonatomic, assign) BOOL isAnimating;
@end

@implementation FVTableViewFocusTrigger

- (instancetype)initWithTableView:(UITableView *)tableView {
    self = [super init];
    if (self) {
        _tableView = tableView;
        [self start];
    }
    return self;
}

- (void)start {
    [super start];
    [self.tableView fv_setStart:YES];
    [self.tableView fv_addDelegate:self];
    [self.tableView fv_setNotifyDelegate:self];
}

- (void)stop {
    [super stop];
    [self.tableView fv_setStart:NO];
    [self.tableView fv_removeDelegate:self];
    [self.tableView fv_setNotifyDelegate:nil];
}

#pragma mark - VFPTableViewUpdateDelegate
- (void)fv_tableViewDidUpdateData:(UITableView *)tableView {
    [self trigger];
}

- (void)fv_tableView:(UITableView *)tableView scrollToRowAtIndexPath:(nonnull NSIndexPath *)indexPath atScrollPosition:(UITableViewScrollPosition)scrollPosition animated:(BOOL)animated {
    // 这里只需要增对无动画的去响应就可以了，因为 animated 会触发 -scrollViewDidEndScrollingAnimation: 回调
    if (!animated) {
        [tableView layoutIfNeeded];
        [self trigger];
    } else {
        // FIXME: 更准确的判断方式 && 如何判断 isAnimating
        CGPoint contentOffset = tableView.contentOffset;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (VFPPointEqualToPoint(contentOffset, tableView.contentOffset)) {
                // 有动画可能没发生滚动，不会触发回调，这里间隔 0.1s 检查下 contentOffset 吧
                [tableView layoutIfNeeded];
                [self trigger];
            }
        });
    }
}

- (void)fv_tableview:(UITableView *)tableView setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {
    // 这里只需要增对无动画的去响应就可以了，因为 animated 会触发 -scrollViewDidEndScrollingAnimation: 回调
    // 或者 contentOffset 相等
    if (!animated || VFPPointEqualToPoint(contentOffset, tableView.contentOffset)) {
        [tableView layoutIfNeeded];
        [self trigger];
    } else {
        self.isAnimating = YES;
    }
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate trigger:self viewWillDisplay:cell indexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate trigger:self viewDidEndDisplaying:cell indexPath:indexPath];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [super scrollViewDidEndScrollingAnimation:scrollView];
    self.isAnimating = NO;
}

- (void)trigger {
    if (self.isAnimating) {
        return;
    }
    [super trigger];
}

@end
