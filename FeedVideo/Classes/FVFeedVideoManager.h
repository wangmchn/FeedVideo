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
/// 通知 delegate 当前聚焦播放器发生了切换，delegate 可通过实现该接口监控当前列表内播放器的切换
/// @param oldPlayer 原聚焦播放器
/// @param newPlayer 新聚焦播放器
- (void)playerManager:(FVFeedVideoManager *)manager didFocusPlayerChange:(id<FVPlayerProtocol>)oldPlayer to:(id<FVPlayerProtocol>)newPlayer;

@end

@protocol FVPlayerProviderProtocol <NSObject>
@required
/// 获取当前 videoInfo 对应的播放器
/// @param videoInfo 由真正承载播放器的 container 提供（即：FVPlayerContainer.fv_videoInfo）
/// @param playerList 当前正在展示的播放器列表。在例如 TikTok 模式的交互形态下，可能在滑动过程中，存在多个正在展示播放器（正常情况下在滑动停止才会添加播放器，但是 TikTok 交互下会在视图即将展示即添加播放器，详见： FVContainerSupplier -fv_canAddPlayerWhenViewWillDisplay:）
- (id<FVPlayerProtocol>)fv_playerForVideoInfo:(id)videoInfo displayingPlayerList:(NSArray<id<FVPlayerProtocol>> *)playerList;

@end

@interface FVFeedVideoManager : NSObject

/// 视图聚焦检测器，用于检测当前视图层级聚焦视图的模块，由 FVFeedVideoManager.supplier 提供
/// @discussion 对于嵌套的场景（例如在一些交互形态下，在 UITableView 中，Cell 上可能还会有一个横向滑动的可播放列表 collectionView），monitor 会找到另一个提供 monitor 视图（FVContainerSupplier）
/// @discussion 即：FVFocusMonitor.focus 可能为 FVContainerSupplier，该 FVContainerSupplier 会继续提供一个 FVFocusMonitor，直到最后的 FVFocusMonitor.focus 为一个真正的可以被添加播放器的视图 FVPlayerContainer
@property (nonatomic, readonly) FVFocusMonitor *monitor;

/// 提供播放器的对象，即组件通过该对象获取对应数据的播放器实例，该接口必须实现
/// @discussion 必须遵循 FVPlayerProviderProtocol 协议，FVVideoFeedManager 会持有该对象的一个弱引用
@property (nonatomic, weak) id<FVPlayerProviderProtocol> playerProvider;

/// 播放器控制的处理类，如无特殊需求，组件会默认初始化一个 handler
/// @discussion 该对象必须遵循 FVPlayerHandlerProtocol 协议，FVVideoFeedManager 会持有该对象的一个强引用
@property (nonatomic, strong) id<FVPlayerHandlerProtocol> playerHandler;

/// 提供视图聚焦检测器的对象，该接口必须实现
/// @discussion 该对象必须遵循 FVContainerSupplier 协议，FVVideoFeedManager 会持有该对象的一个弱引用
@property (nonatomic, weak) id<FVContainerSupplier> supplier;

/// 代理回调，用于通知播放器切换等回调，如无需求，可不实现
/// FVVideoFeedManager 会持有该对象的一个弱引用
@property (nonatomic, weak, nullable) id<FVFeedVideoManagerDelegate> delegate;

/// 实现预加载接口的对象，如无预加载数据的需求，可不实现
/// @discussion 该对象必须遵循 FVPreloadMgrProtocol 协议，FVVideoFeedManager 会持有该对象的一个弱引用
@property (nonatomic, weak, nullable) id<FVPreloadMgrProtocol> preloadMgr;

/// 当前聚焦的播放器
@property (nonatomic, strong, readonly, nullable) id<FVPlayerProtocol> focusPlayer;

/// 禁用，默认为 NO
@property (nonatomic, assign) BOOL disable;

/// 单次预加载数据的最大个数（默认3）
/// @discussion 组件内部只负责触发对数据进行预加载的时机，并限制单次预加载数据的最大个数，业务侧需要自己处理去重及暂停等逻辑
@property (nonatomic, assign) NSUInteger maximumPreloadDataCount;

/// 单次预加载播放器的最大个数（默认2）
/// @discussion 组件内部只负责触发对播放器进行预加载的时机，并限制单次预加载播放器的最大个数，受制于业务侧可提供的播放器个数限制
@property (nonatomic, assign) NSUInteger maximumPreloadPlayerCount;

/// 移除所有播放器，并暂停播放
- (void)removeAllPlayers;

/// 移除指定播放器，并暂停播放
/// @param player 指定的播放器
- (void)removePlayer:(id<FVPlayerProtocol>)player;

/// 移除指定播放器，并暂停播放
/// @param player 指定的播放器
/// @param context 上下文信息，该信息会最终传递给实现 FVPlayerContainer 的 view
- (void)removePlayer:(id<FVPlayerProtocol>)player context:(nullable FVContext *)context;

/// 移除指定播放器，并控制是否需要暂停播放（例如在做播放器的转场动画时，且不需要暂停时，可通过该接口移除）
/// @param player 指定的播放器
/// @param context 上下文参数，该信息会最终传递给实现 FVPlayerContainer 的 view
- (void)removePlayer:(id<FVPlayerProtocol>)player pause:(BOOL)pause context:(nullable FVContext *)context;

/// 指定对应位置进行播放，可以通过 node.child 来指定嵌套多层的指定播放
/// @param node 指定播放的位置信息
/// @param context 上下文信息，该信息会最终传递给实现 FVPlayerContainer 的 view
/// @discussion 在有嵌套的播放列表时，如需要指定第一个位置中的第二个播放，可以使用如下的调用方式：
/// @code
/// NSIndexPath *root = [NSIndexPath indexPathForRow:0 inSection:0];
/// NSIndexPath *child = [NSIndexPath indexPathForRow:1 inSection:0];
/// [manager appointNode:FVIndexPathNode.fv_root(root).fv_child(child)];
- (void)appointNode:(FVIndexPathNode *)node context:(nullable FVContext *)context;

/// 指定对应位置进行播放，可以通过 node.child 来指定嵌套多层的指定播放，外部可通过该方法指定使用的播放器
/// @discussion 例如在转场时，可能在上一个场景将播放器实例切换到下一个场景，此时希望使用同一个播放器来播放，以保证播放的连贯性，可通过该接口来实现
/// @param node 指定播放的位置信息
/// @param player 指定使用的播放器
/// @param context 上下文信息，该信息会最终传递给实现 FVPlayerContainer 的 view
- (void)appointNode:(FVIndexPathNode *)node player:(id<FVPlayerProtocol>)player play:(BOOL)play context:(nullable FVContext *)context;

/// 重新计算聚焦
/// @discussion 该接口会触发 FVMonitor 重新检测当前视图是否有聚焦变换
- (void)recalculate;

@end

NS_ASSUME_NONNULL_END
