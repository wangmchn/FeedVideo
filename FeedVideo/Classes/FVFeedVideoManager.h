//
//  FVFeedVideoManager.h
//  FeedVideo
//
//  Created by Mark on 2019/9/25.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FVContainerSupplier.h"
#import "FVPlayerContainer.h"
#import "FVFocusMonitor.h"
@class FVFeedVideoManager, FVContext;
@protocol FVPlayerProtocol, FVPreloadMgrProtocol, FVPlayerHandlerProtocol;

NS_ASSUME_NONNULL_BEGIN

@protocol FVFeedVideoManagerDelegate <NSObject>
@optional
- (void)playerManager:(FVFeedVideoManager *)manager didFocusPlayerChange:(id<FVPlayerProtocol>)oldPlayer to:(id<FVPlayerProtocol>)newPlayer;

@end

@protocol FVPlayerProviderProtocol <NSObject>
@required
- (id<FVPlayerProtocol>)fv_playerForVideoInfo:(id)videoInfo exceptPlayerList:(NSArray<id<FVPlayerProtocol>> *)playerList;

@end

@interface FVFeedVideoManager : NSObject

/**
 视图聚焦检测器，用于检测当前视图层级聚焦视图的模块，由外界提供 (self.supplier提供)
 @discussion 对于嵌套的场景（例如 tableView 中嵌套有 collectionView），monitor 会找到另一个提供 monitor 视图, 可能的层级关系如下图所示：
 @code
 * 嵌套的场景, 层级如下：
 * -> monitor -> supplier -> monitor -> supplier .... -> monitor -> container
 * 如果没有嵌套的场景, 则层级如下：
 * -> monitor -> container -> nil
 */
@property (nonatomic, readonly) FVFocusMonitor *monitor;

/**
 提供播放器的对象
 @discussion 该对象必须遵循 FVPlayerProviderProtocol 协议，FVVideoFeedManager 会持有该对象的一个弱引用
 */
@property (nonatomic, weak) id<FVPlayerProviderProtocol> playerProvider;

/**
提供播放控制的处理类
业务如果未传入，会使用组件的默认实现
@discussion 该对象必须遵循 FVPlayerHandlerProtocol 协议，FVVideoFeedManager 会持有该对象的一个强引用
*/
@property (nonatomic, strong) id<FVPlayerHandlerProtocol> playerHandler;

/**
 提供视图聚焦检测器的对象
 @discussion 该对象必须遵循 FVContainerSupplier 协议，FVVideoFeedManager 会持有该对象的一个弱引用
 */
@property (nonatomic, weak) id<FVContainerSupplier> supplier;

/**
 代理回调，FVVideoFeedManager 会持有该对象的一个弱引用
 */
@property (nonatomic, weak, nullable) id<FVFeedVideoManagerDelegate> delegate;

/**
 实现预加载接口的对象
 @discussion 该对象必须遵循 FVPreloadMgrProtocol 协议，FVVideoFeedManager 会持有该对象的一个弱引用
 */
@property (nonatomic, weak, nullable) id<FVPreloadMgrProtocol> preloadMgr;

/**
 当前聚焦的播放器
 @discussion 该对象必须遵循 FVPlayerProtocol 协议，FVVideoFeedManager 会持有该对象的一个强引用
 */
@property (nonatomic, strong, readonly, nullable) id<FVPlayerProtocol> focusPlayer;

/// 禁用
@property (nonatomic, assign) BOOL disable;

/**
 单次预加载数据的最大个数（默认3）
 @discussion 组件内部只负责触发对数据进行预加载的时机，并限制单次预加载数据的最大个数，业务侧需要自己处理去重及暂停等逻辑
 */
@property (nonatomic, assign) NSUInteger maximumPreloadDataCount;

/**
 单次预加载播放器的最大个数（默认2）
 @discussion 组件内部只负责触发对播放器进行预加载的时机，并限制单次预加载播放器的最大个数，受制于业务侧可提供的播放器个数限制
 */
@property (nonatomic, assign) NSUInteger maximumPreloadPlayerCount;

/** 移除所有播放器 */
- (void)removeAllPlayers;

/**
 移除播放器，并停止播放

 @param player 指定的播放器
 */
- (void)removePlayer:(id<FVPlayerProtocol>)player;

- (void)removePlayer:(id<FVPlayerProtocol>)player context:(nullable FVContext *)context;

/**
移除播放器

@param player 指定的播放器
@param context 上下文参数
*/
- (void)removePlayer:(id<FVPlayerProtocol>)player pause:(BOOL)pause context:(nullable FVContext *)context;

/**
 指定对应位置进行播放，可以通过 node.child 来指定嵌套多层的指定播放
 
 @param node 指定播放的位置信息
 @param context 上下文信息，最终会透传给 container
 @discussion 例如需要指定第一个位置中的第二个播放，可以使用如下的调用方式：
 @code
 NSIndexPath *root = [NSIndexPath indexPathForRow:0 inSection:0];
 NSIndexPath *child = [NSIndexPath indexPathForRow:1 inSection:0];
 [manager appointNode:FVIndexPathNode.fv_root(root).fv_child(child)];
 */
- (void)appointNode:(FVIndexPathNode *)node context:(nullable FVContext *)context;

/**
 指定对应位置进行播放，可以通过 node.child 来指定嵌套多层的指定播放，外部可通过该方法指定使用的播放器

 @param node 指定播放的位置信息
 @param player 指定使用的播放器
 @param context 上下文信息，最终会透传给 container
 */
- (void)appointNode:(FVIndexPathNode *)node player:(id<FVPlayerProtocol>)player play:(BOOL)play context:(nullable FVContext *)context;

/** 重新计算聚焦 */
- (void)recalculate;

@end

NS_ASSUME_NONNULL_END
