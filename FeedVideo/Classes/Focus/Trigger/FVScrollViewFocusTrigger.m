//
//  FVScrollViewFocusTrigger.m
//  FeedVideo
//
//  Created by turbochen on 2020/7/8.
//  Copyright © 2020 Tencent.Inc. All rights reserved.
//

#import "FVScrollViewFocusTrigger.h"

@interface FVScrollViewFocusTrigger () <UIScrollViewDelegate>

@end

@implementation FVScrollViewFocusTrigger

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [self trigger];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self trigger];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self trigger];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self trigger];
    }
}

@end
