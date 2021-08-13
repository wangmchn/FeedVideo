//
//  FVPlayerHandlerProtocol.h
//  FeedVideo
//
//  Created by 王敏 on 2019/10/3.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FVPlayerContainer.h"
#import "FVContainerSupplier.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FVPlayerHandlerDataSource;
@protocol FVPlayerHandlerProtocol;
@protocol FVPlayerHandlerDelegate;

@protocol FVPlayerHandlerDataSource <NSObject>
@required
- (id<FVPlayerProtocol>)playerWithVideoInfo:(id)videoInfo displayingPlayerList:(NSArray<id<FVPlayerProtocol>> *)playerList;

@end


@protocol FVPlayerHandlerDelegate <NSObject>
@optional
- (void)handler:(id<FVPlayerHandlerProtocol>)handler didPlayerFinish:(id<FVPlayerProtocol>)player;
- (void)handler:(id<FVPlayerHandlerProtocol>)handler didFocusPlayerChange:(id<FVPlayerProtocol>)oldPlayer to:(id<FVPlayerProtocol>)newPlayer;
@end


@protocol FVPlayerHandlerProtocol <NSObject>
@required
@property (nonatomic, strong, readonly) id<FVPlayerProtocol> focusPlayer;

@property (nonatomic, weak) id<FVPlayerHandlerDataSource> dataSource;
@property (nonatomic, weak) id<FVPlayerHandlerDelegate> delegate;

- (void)containerWillDisplay:(UIView<FVPlayerContainer> *)playerContainer forSupplier:(id<FVContainerSupplier>)supplier;

- (void)containerDidEndDisplay:(UIView<FVPlayerContainer> *)playerContainer forSupplier:(id<FVContainerSupplier>)supplier;

- (BOOL)containerDidBecomeFocus:(UIView<FVPlayerContainer> *)playerContainer appointPlayer:(nullable id<FVPlayerProtocol>)appointPlayer startPlay:(BOOL)startPlay context:(nullable FVContext *)context;

- (void)containerDidResignFocus:(UIView<FVPlayerContainer> *)playerContainer context:(nullable FVContext *)context;

- (void)removeAllPlayer;

- (void)removePlayer:(id<FVPlayerProtocol>)player pause:(BOOL)pause context:(nullable FVContext *)context;

- (void)preloadPlayerList:(NSArray *)videoDataList;

@end

NS_ASSUME_NONNULL_END
