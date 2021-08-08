//
//  FVPlayerHandler.m
//  FeedVideo
//
//  Created by 王敏 on 2019/10/07.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVPlayerHandler.h"
#import "FVContainerSupplier.h"
#import "FVPlayerContainer.h"
#import "FVFeedVideoUtil.h"
#import <objc/runtime.h>

NS_INLINE void fv_addPlayer(id<FVPlayerProtocol> player, UIView<FVPlayerContainer> *container, id context) {
    if (!player || !container) {
        return;
    }
    if (player.fv_playerView.superview == container.fv_playerContainerView) {
        return;
    }

    fv_bind(container, player);
    
    if ([container respondsToSelector:@selector(fv_willAddPlayer:context:)]) {
        [container fv_willAddPlayer:player context:context];
    }
    player.fv_playerView.frame = container.fv_playerContainerView.bounds;
    [container.fv_playerContainerView addSubview:player.fv_playerView];
    if ([container respondsToSelector:@selector(fv_didAddPlayer:context:)]) {
        [container fv_didAddPlayer:player context:context];
    }
}

NS_INLINE void fv_preload(id<FVPlayerProtocol> player, id data) {
    if (!player || !data) {
        return;
    }
    
    if (![player fv_isPlayingData:data]) {
        [player fv_preload:data];
    }
}

@interface FVPlayerHandler ()
/// 当前聚焦播放的播放器
@property (nonatomic, strong, readwrite) id<FVPlayerProtocol> focusPlayer;
@property (nonatomic, readonly) void (^playFinishHandler)(id<FVPlayerProtocol> player);
@end

@implementation FVPlayerHandler
@synthesize dataSource;
@synthesize delegate;

#pragma mark - Private Method

- (void (^)(id<FVPlayerProtocol> player))playFinishHandler {
    __weak typeof(self) weak_self = self;
    return ^void(id<FVPlayerProtocol> player) {
        __strong typeof(weak_self) strong_self = weak_self;
        if ([strong_self respondsToSelector:@selector(handler:didPlayerFinish:)]) {
            [strong_self.delegate handler:strong_self didPlayerFinish:strong_self.focusPlayer];
        }
    };
}

- (void)setFocusPlayer:(id<FVPlayerProtocol>)focusPlayer {
    if (focusPlayer == _focusPlayer) {
        return;
    }
    id<FVPlayerProtocol> oldPlayer = _focusPlayer;
    _focusPlayer = focusPlayer;
    if ([self.delegate respondsToSelector:@selector(handler:didFocusPlayerChange:to:)]) {
        [self.delegate handler:self didFocusPlayerChange:oldPlayer to:focusPlayer];
    }
}

#pragma mark - Player
- (id<FVPlayerProtocol>)getPlayerWithVideoInfo:(id)videoInfo {
    if (!videoInfo) {
        return nil;
    }
    id<FVPlayerProtocol> resultPlayer = [self.dataSource playerWithVideoInfo:videoInfo displayingPlayerList:(self.focusPlayer ? @[self.focusPlayer] : nil)];
    return resultPlayer;
}

#pragma mark - Preload
- (void)preloadPlayerWithVideoData:(id)videoData {
    id<FVPlayerProtocol> player = [self getPlayerWithVideoInfo:videoData];
	
	if (!player || [player isEqual:self.focusPlayer]) {
		return;
	}
    fv_preload(player, videoData);
}

#pragma mark - Public Method
- (void)containerWillDisplay:(UIView<FVPlayerContainer> *)playerContainer forSupplier:(id<FVContainerSupplier>)supplier {
    if (![supplier respondsToSelector:@selector(fv_canAddPlayerWhenViewWillDisplay:)]) {
        return;
    }
    if (![supplier fv_canAddPlayerWhenViewWillDisplay:playerContainer]) {
        return;
    }
    if (fv_getPlayer(playerContainer)) {
        return;
    }

    id<FVPlayerProtocol> player = [self getPlayerWithVideoInfo:playerContainer.fv_videoInfo];
    if (!player) {
        return;
    }
    
    if (fv_getContainer(player)) {
        return;
    }
    fv_addPlayer(player, playerContainer, nil);
    fv_preload(player, playerContainer.fv_videoInfo);
}

- (void)containerDidEndDisplay:(UIView<FVPlayerContainer> *)playerContainer
                   forSupplier:(id<FVContainerSupplier>)supplier {
    if (![supplier respondsToSelector:@selector(fv_canAddPlayerWhenViewWillDisplay:)]) {
        return;
    }
    
    if (![supplier fv_canAddPlayerWhenViewWillDisplay:playerContainer]) {
        return;
    }
    
    [self removePlayer:fv_getPlayer(playerContainer) pause:YES context:nil];
}

- (BOOL)containerDidBecomeFocus:(UIView<FVPlayerContainer> *)playerContainer
                  appointPlayer:(id<FVPlayerProtocol>)appointPlayer
                      startPlay:(BOOL)startPlay
                        context:(nullable FVContext *)context {
    NSParameterAssert(playerContainer);
    if (!playerContainer) {
        return NO;
    }

    if (self.focusPlayer == appointPlayer && fv_isOnContainer(self.focusPlayer, playerContainer)) {
        return YES;
    }
    
    [self removePlayer:self.focusPlayer pause:YES context:context];
    
    if (!fv_canAddPlayer(playerContainer)) {
        return NO;
    }
    
    id<FVPlayerProtocol> attachPlayer = appointPlayer;
    if (!attachPlayer) {
        attachPlayer = [self getPlayerWithVideoInfo:playerContainer.fv_videoInfo];
    }
    
    if (!attachPlayer) {
        NSParameterAssert(attachPlayer);
        return NO;
    }
    
    [self addPlayerToFocusContainer:playerContainer player:attachPlayer startPlay:startPlay context:context];
    
    return YES;
}

- (void)addPlayerToFocusContainer:(UIView<FVPlayerContainer> *)playerContainer
                           player:(id<FVPlayerProtocol>)player
                        startPlay:(BOOL)startPlay
                          context:(nullable FVContext *)context {
    
    self.focusPlayer = player;
    
    fv_addPlayer(player, playerContainer, context);
    
    if (startPlay) {
        id videoInfo = playerContainer.fv_videoInfo;
        if ([self.focusPlayer fv_isPlayingData:videoInfo]) {
            [self.focusPlayer fv_play];
        } else {
            [self.focusPlayer fv_load:videoInfo];
        }
    }
    
    self.focusPlayer.fv_finishBlock = [self playFinishHandler];
}

- (void)containerDidResignFocus:(UIView<FVPlayerContainer> *)playerContainer context:(nullable FVContext *)context {
    if (!playerContainer) {
        return;
    }
    if (!fv_isBind(playerContainer, self.focusPlayer)) {
        return;
    }
    
    [self removePlayer:self.focusPlayer pause:YES context:context];
}

- (void)removeAllPlayer {
    [self removePlayer:self.focusPlayer pause:YES context:nil];
}

- (void)removePlayer:(id<FVPlayerProtocol>)player pause:(BOOL)pause context:(nullable FVContext *)context {
    if (!player) {
        return;
    }
    
    UIView<FVPlayerContainer> *playerContainer = fv_getContainer(player);
    if (!playerContainer) {
        return;
    }
    
    if (self.focusPlayer == player) {
        self.focusPlayer = nil;
    }
    
    if ([playerContainer respondsToSelector:@selector(fv_willRemovePlayer:context:)]) {
        [playerContainer fv_willRemovePlayer:player context:context];
    }
    
    [player.fv_playerView removeFromSuperview];
    if (pause) {
        [player fv_pause];
    }
    player.fv_finishBlock = nil;
    fv_unbind(playerContainer, player);
    
    if ([playerContainer respondsToSelector:@selector(fv_didRemovePlayer:context:)]) {
        [playerContainer fv_didRemovePlayer:player context:context];
    }
}

- (void)preloadPlayerList:(NSArray *)videoDataList {
    if (videoDataList.count == 0) {
        return;
    }
    
    for (id videoData in videoDataList) {
        [self preloadPlayerWithVideoData:videoData];
    }
}

@end
