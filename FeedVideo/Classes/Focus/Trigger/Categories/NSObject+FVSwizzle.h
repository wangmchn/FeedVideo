//
//  NSObject+FVSwizzle.h
//  FeedVideo
//
//  Created by Mark on 2019/10/2.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (FVSwizzle)

+ (BOOL)fv_swizzleInstanceMethod:(SEL)originalSelector with:(SEL)swizzledSelector;

+ (BOOL)fv_swizzleClassMethod:(SEL)originalSelector with:(SEL)swizzledSelector;

@end

NS_ASSUME_NONNULL_END
