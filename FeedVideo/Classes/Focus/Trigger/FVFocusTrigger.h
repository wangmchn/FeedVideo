//
//  FVFocusTrigger.h
//  FeedVideo
//
//  Created by Mark on 2019/9/25.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class FVFocusTrigger;

NS_ASSUME_NONNULL_BEGIN

extern BOOL VFPPointEqualToPoint(CGPoint point1, CGPoint point2);

@protocol FVFocusTriggerDelegate <NSObject>
@required

/**
 视图位置、元素等发生改变，触发外界进行重新计算

 @param trigger 当前触发器
 */
- (void)triggerDidTrigger:(FVFocusTrigger *)trigger;

/**
 视图已经不再展示的回调

 @param trigger 当前触发器
 @param view 不可见的视图
 @param indexPath 视图位置信息
 */
- (void)trigger:(FVFocusTrigger *)trigger viewDidEndDisplaying:(__kindof UIView *)view indexPath:(NSIndexPath *)indexPath;

/**
 视图即将出现的回调

 @param trigger 当前触发器
 @param view 即将展示的视图
 @param indexPath 视图位置信息
 */
- (void)trigger:(FVFocusTrigger *)trigger viewWillDisplay:(__kindof UIView *)view indexPath:(NSIndexPath *)indexPath;

@end

@interface FVFocusTrigger : NSObject
/// 代理
@property (nonatomic, weak) id<FVFocusTriggerDelegate> delegate;
/// 当前是否处于活跃状态
@property (nonatomic, assign, readonly, getter=isActive) BOOL active;

/// 启动
- (void)start;
/// 停止
- (void)stop;

/**
 触发 Trigger 进行一次视图位置、元素改变的回调
 */
- (void)trigger;

@end

NS_ASSUME_NONNULL_END
