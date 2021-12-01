//
//  UIView+Focus.h
//  FeedVideo
//
//  Created by markmwang on 2021/12/1.
//

#import <UIKit/UIKit.h>
#import "FVFocusMonitor.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIView (Focus)

- (void)fv_focus;

- (void)fv_focusWithContext:(nullable id)context;

- (void)fv_focusWithType:(FVFocusType)type context:(nullable id)context;

- (void)fv_focusWithType:(FVFocusType)type context:(nullable id)context alsoNode:(FVIndexPathNode *)node;

@end

NS_ASSUME_NONNULL_END
