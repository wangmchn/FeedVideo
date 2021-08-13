//
//  FVFocusMonitor.h
//  FeedVideo
//
//  Created by Mark on 2019/9/25.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FVFocusTrigger.h"
#import "FVFocusCalculator.h"
#import "FVIndexPathNode.h"

@class FVFocusMonitor;

NS_ASSUME_NONNULL_BEGIN

@protocol FVFocusMonitorDelegate <NSObject>
@required

/// 聚焦视图发生变化时的回调
/// @discussion view 为 `UIView<FVPlayerContainer> *` or `UIView<FVContainerSupplier> *` 其中一种
/// @param monitor 聚焦检测器
/// @param oldView 原聚集视图，可能为 nil
/// @param newView 新聚焦视图，可能为 nil
/// @param context 上下文信息
- (void)monitor:(FVFocusMonitor *)monitor focusDidChange:(nullable __kindof UIView *)oldView to:(nullable __kindof UIView *)newView context:(nullable FVContext *)context;

/// 聚焦视图触发，找到相同的视图的回调
/// @param monitor 聚焦检测器
/// @param view 找到的聚焦视图
/// @param context 上下文信息
- (void)monitor:(FVFocusMonitor *)monitor didFindSame:(nullable __kindof UIView *)view context:(nullable FVContext *)context;

/// 聚焦视图触发，找到非自动播放的视图
/// @param monitor 聚焦检测器
/// @param view 找到的聚焦视图，但是因为非自动播放聚焦失败
/// @param context 上下文信息，自动触发为 nil, 由外界 appoint 透传
- (void)monitor:(FVFocusMonitor *)monitor didAbort:(nonnull __kindof UIView *)view context:(nullable FVContext *)context;

/// 即将展示的回调
/// @discussion container 为 `UIView<FVPlayerContainer> *` or `UIView<FVContainerSupplier> *` 其中一种
/// @param monitor 聚焦检测器
/// @param container 即将展示的视图
/// @param indexPath 视图位置
- (void)monitor:(FVFocusMonitor *)monitor containerWillDisplay:(__kindof UIView *)container indexPath:(NSIndexPath *)indexPath;

/// 停止展示回调
/// @param monitor 聚焦检测器
/// @param container 停止展示的回调
/// @param indexPath 视图位置
- (void)monitor:(FVFocusMonitor *)monitor containerDidEndDisplay:(__kindof UIView *)container indexPath:(NSIndexPath *)indexPath;

@end
typedef void (^FVAppointCompletionBlock)(__kindof UIView *_Nullable oldView, __kindof UIView *_Nullable newView);

@interface FVFocusMonitor : NSObject
/// 生成当前 monitor 的 supplier, 记录用于反向遍历
@property (nonatomic, weak) id<FVContainerSupplier> ownerSupplier;
/// delegate
@property (nonatomic, weak, nullable) id<FVFocusMonitorDelegate> delegate;
/// 当前聚焦的视图，为 `UIView<FVPlayerContainer> *` or `UIView<FVContainerSupplier> *` 其中一种
@property (nonatomic, readonly, nullable) __kindof UIView *focus;
/// 聚焦失败的视图，比如滑动停止时，找到非自动播放的容器
@property (nonatomic, readonly, nullable) __kindof UIView *abort;
/// 聚焦视图对应的 indexPath 信息
@property (nonatomic, readonly, nullable) NSIndexPath *focusIndexPath;
/// 聚焦视图对应的 indexPath 信息
@property (nonatomic, readonly, nullable) NSIndexPath *abortIndexPath;
/// 聚焦的 indexPath 链路
@property (nonatomic, readonly, nullable) FVIndexPathNode *focusIndexPathNode;
/// 聚焦失败的 indexPath 链路
@property (nonatomic, readonly, nullable) FVIndexPathNode *abortIndexPathNode;
/// 触发器
@property (nonatomic, strong, nullable) __kindof FVFocusTrigger *trigger;
/// 计算器
@property (nonatomic, strong, nullable) __kindof FVFocusCalculator *calculator;
/// 获取链尾的 monitor
@property (nonatomic, readonly) FVFocusMonitor *tail;
/// 禁用
@property (nonatomic, assign) BOOL disable;

/**
 是否应该切换到新聚焦视图
 
 @param focus 已经聚焦的视图
 @param target 新算出来的聚焦视图
 @return NO：不切换到target   YES：切换到target
 
 默认：focusContainer和target都实现了FVPlayerContainer，且focusContainer满足计算聚焦视图需要达到的可见性的时候，返回NO；否则返回YES
 */
@property (nonatomic, copy, null_resettable) BOOL (^shouldChangeFocusContainerToTarget)(__kindof UIView *focusContainer, __kindof UIView *target);

/**
 从当前 monitor 开始，遍历整个链表
 @discussion 如果 reverse 为 YES，则向前遍历，否则向后遍历。
 
 @param reverse 是否反向遍历
 @param block 回调接口
 */
- (void)enumerateMonitorChainReverse:(BOOL)reverse usingBlock:(void (^_Nullable)(FVFocusMonitor *monitor, BOOL *stop))block;

/**
 构造方法，必须初始化传入一个触发器和聚焦计算器

 @param trigger 触发器
 @param calculator 聚焦计算器
 @return 实例
 */
- (instancetype)initWithTrigger:(__kindof FVFocusTrigger *)trigger
                     calculator:(__kindof FVFocusCalculator *)calculator NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 指定对应位置进行播放，可以通过 node.child 来指定嵌套多层的指定播放
 @see -appointNode:usingBlock:

 @param node 位置节点
 @param context 上下文信息，最终会透传给 container
 */
- (void)appointNode:(FVIndexPathNode *)node context:(nullable FVContext *)context;

/**
 指定对应位置进行播放，可以通过 node.child 来指定嵌套多层的指定播放
 @param node 位置节点
 @param makeFocus 是否需要调用聚焦
 @param context 上下文信息，最终会透传给 container
 */
- (void)appointNode:(FVIndexPathNode *)node makeFocus:(BOOL)makeFocus context:(nullable FVContext *)context;

/**
 聚焦完成再进行指定位置的播放
 @param node 位置节点
 @param afterFocus 是否在聚焦之后才添加播放器
 @param context 上下文信息，最终会透传给 container
 */
- (void)appointNode:(FVIndexPathNode *)node afterFocus:(BOOL)afterFocus context:(nullable FVContext *)context;

/**
 指定对应位置进行播放，可以通过 node.child 来指定嵌套多层的指定播放
 @param node 位置节点
 @param completionBlock 完成回调，如未设置 block 则会通过 delegate 方法回调
 @param context 上下文信息，最终会透传给 container
 @discussion 例如需要指定第一个位置中的第二个播放，可以使用如下的调用方式：
 @code
 NSIndexPath *root = [NSIndexPath indexPathForRow:0 inSection:0];
 NSIndexPath *child = [NSIndexPath indexPathForRow:1 inSection:0];
 [monitor appointNode:FVIndexPathNode.fv_root(root).fv_child(child)];
 */
- (void)appointNode:(FVIndexPathNode *)node makeFocus:(BOOL)makeFocus context:(nullable FVContext *)context usingBlock:(nullable FVAppointCompletionBlock)completionBlock;

/**
 重新触发一次计算
 */
- (void)recalculate;

/**
 清理当前 monitor 保存的聚焦视图等数据
 */
- (void)clear;

/**
清理当前 monitor 保存的聚焦视图等数据，并通知代理
*/
- (void)clearAndNotify;

@end

@interface FVFocusMonitor (UICollectionView)

/**
 对 UICollectionView 增加支持的一个便利构造方法

 @param collectionView collectionView
 @return FVFocusMonitor 实例
 */
- (instancetype)initWithCollectionView:(UICollectionView *)collectionView;

@end

@interface FVFocusMonitor (UITableView)

/**
 对 UITableView 增加支持的一个便利构造方法
 
 @param tableView tableView
 @return FVFocusMonitor 实例
 */
- (instancetype)initWithTableView:(UITableView *)tableView;

@end

NS_ASSUME_NONNULL_END
