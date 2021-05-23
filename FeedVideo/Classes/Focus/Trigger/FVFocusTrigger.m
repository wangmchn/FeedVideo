//
//  FVFocusTrigger.m
//  FeedVideo
//
//  Created by Mark on 2019/9/25.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVFocusTrigger.h"

BOOL VFPPointEqualToPoint(CGPoint point1, CGPoint point2) {
    return fabs(point1.x - point2.x) < 1 && fabs(point1.y - point2.y) < 1;
}

@interface FVFocusTrigger ()

@end

@implementation FVFocusTrigger

- (void)start {
    _active = YES;
}

- (void)stop {
    _active = NO;
}

- (void)trigger {
    [self.delegate triggerDidTrigger:self];
}

@end

