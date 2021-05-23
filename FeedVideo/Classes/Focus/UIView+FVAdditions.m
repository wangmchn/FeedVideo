//
//  UIView+FVAdditions.m
//  FeedVideo
//
//  Created by Mark on 2019/11/21.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "UIView+FVAdditions.h"
#import <objc/runtime.h>

@implementation UIView (FVAdditions)

- (BOOL)_fv_willEndDisplaying {
    return [objc_getAssociatedObject(self, @selector(_fv_willEndDisplaying)) boolValue];
}

- (void)set_fv_willEndDisplaying:(BOOL)_fv_willEndDisplaying {
    objc_setAssociatedObject(self, @selector(_fv_willEndDisplaying), @(_fv_willEndDisplaying), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)set_fv_isDisplay:(BOOL)_fv_isDisplay {
    objc_setAssociatedObject(self, @selector(_fv_isDisplay), @(_fv_isDisplay), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)_fv_isDisplay {
    return [objc_getAssociatedObject(self, @selector(_fv_isDisplay)) boolValue];
}

- (void)set_fv_lastIdentifier:(NSString *)_fv_lastIdentifier {
    objc_setAssociatedObject(self, @selector(_fv_lastIdentifier), _fv_lastIdentifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)_fv_lastIdentifier {
    return objc_getAssociatedObject(self, @selector(_fv_lastIdentifier));
}

@end
