//
//  UIView+FVAdditions.h
//  FeedVideo
//
//  Created by Mark on 2019/11/21.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (FVAdditions)
@property (nonatomic, copy) NSString *_fv_lastIdentifier;
@property (nonatomic, assign) BOOL _fv_isDisplay;
@property (nonatomic, assign) BOOL _fv_willEndDisplaying;
@end

NS_ASSUME_NONNULL_END
