//
//  FVAVPlayer.m
//  VideoFeedExample
//
//  Created by markmwang on 2020/8/26.
//  Copyright © 2020 Tencent.Inc. All rights reserved.
//

#import "FVAVPlayer.h"
#import <AVFoundation/AVFoundation.h>
@import KVOController;

@interface FVAVPlayer ()

@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) AVPlayerItem *playerItem;

@property (nonatomic, copy) void (^completionBlock)(id<FVPlayerProtocol> player);

@property (nonatomic, strong) NSHashTable<id<FVAVPlayerDelegate>> *delegates;

@end

@implementation FVAVPlayer

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(playerDidFinishPlay:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        _delegates = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)loadURL:(NSString *)strURL {
    [self.KVOController unobserveAll];
    self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:strURL]];
    if (self.player) {
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    } else {
        self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    }
    if (self.playerLayer) {
        [self.playerLayer removeFromSuperlayer];
    }
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.backgroundColor = [UIColor blackColor].CGColor;
    [self.layer addSublayer:self.playerLayer];
    [self setNeedsLayout];
    __weak typeof(self) weak_self = self;
    [self.KVOController observe:self.playerItem keyPath:@"status" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        __strong typeof(weak_self) strong_self = weak_self;
        AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey] intValue];
        NSLog(@"player status change: %@", @(status));
        switch (status) {
            case AVPlayerItemStatusFailed:
                break;
            case AVPlayerItemStatusReadyToPlay:
                if (strong_self.preloading) {
                    return;
                }
                [strong_self.player play];
                break;
            case AVPlayerItemStatusUnknown:
                break;
            default:
                break;
        }
    }];
}

- (void)playerDidFinishPlay:(NSNotification *)notification {
    if (notification.object != self.playerItem) {
        return;
    }
    
    [self.delegates.allObjects enumerateObjectsUsingBlock:^(id<FVAVPlayerDelegate>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(playerOnComplete)]) {
            [obj playerOnComplete];
        }
    }];
    
    !self.completionBlock ?: self.completionBlock(self);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.playerLayer.frame = self.bounds;
    [CATransaction commit];
}

#pragma mark - Public Method
- (void)addDelegate:(id<FVAVPlayerDelegate>)delegate {
    if (!delegate) {
        return;
    }

    [self.delegates addObject:delegate];
}

- (void)removeDelegate:(id<FVAVPlayerDelegate>)delegate {
    if (!delegate) {
        return;
    }
    
    [_delegates removeObject:delegate];
}

#pragma mark - Private
- (BOOL)isContainDelegate:(id<FVAVPlayerDelegate>)delegate {
    if (!delegate) {
        return NO;
    }
    
    return [_delegates containsObject:delegate];
}

@end

@implementation FVAVPlayer (FeedVideo)

- (BOOL)fv_isPlayingData:(id)data {
    if (![data isKindOfClass:[NSString class]]) {
        return NO;
    }
    AVURLAsset *asset = [self.playerItem.asset isKindOfClass:AVURLAsset.class] ? (AVURLAsset *)self.playerItem.asset : nil;
    return [asset.URL.absoluteString isEqualToString:data];
}

- (void)fv_setFinishBlock:(void (^)(id<FVPlayerProtocol> _Nonnull))fv_finishBlock {
    self.completionBlock = fv_finishBlock;
}

- (UIView *)fv_playerView {
    return self;
}

- (void)fv_load:(nonnull id)data {
    if (![data isKindOfClass:[NSString class]]) {
        return;
    }
    self.preloading = NO;
    [self loadURL:data];
}

- (void)fv_pause {
    [self.player pause];
}

- (void)fv_play {
    [self.player play];
}

- (void)fv_preload:(nonnull id)data {
    if (![data isKindOfClass:[NSString class]]) {
        return;
    }
    self.preloading = YES;
    [self loadURL:data];
}

- (void)fv_replay {
    [self.playerItem seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        NSLog(@"replay result: %@", @(finished));
    }];
}

- (void)fv_stop {
    [self.player pause];
    [self.player replaceCurrentItemWithPlayerItem:nil];
}

@end
