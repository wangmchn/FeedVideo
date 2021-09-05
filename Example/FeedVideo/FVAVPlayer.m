//
//  FVAVPlayer.m
//  VideoFeedExample
//
//  Created by markmwang on 2020/8/26.
//  Copyright © 2020 Tencent.Inc. All rights reserved.
//

#import "FVAVPlayer.h"
#import <AVFoundation/AVFoundation.h>

NS_INLINE NSURL *FVFileURLWithName(NSString *name) {
    NSString *strURL = [[NSBundle mainBundle] pathForResource:name ofType:nil];
    return [NSURL fileURLWithPath:strURL];
}

@import KVOController;

@interface FVAVPlayer ()

@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) AVPlayerItem *playerItem;

@property (nonatomic, copy) void (^completionBlock)(id<FVPlayerProtocol> player);

@property (nonatomic, strong) NSHashTable<id<FVAVPlayerDelegate>> *delegates;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@end

@implementation FVAVPlayer

- (UIActivityIndicatorView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [_indicatorView sizeToFit];
        _indicatorView.hidesWhenStopped = YES;
    }
    return _indicatorView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(playerDidFinishPlay:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        _delegates = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)loadURL:(NSURL *)URL {
    [self.KVOController unobserveAll];
    self.playerItem = [AVPlayerItem playerItemWithURL:URL];
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
    [self addSubview:self.indicatorView];
    [self.indicatorView startAnimating];
    [self.KVOController observe:self.playerItem keyPath:@"status" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        __strong typeof(weak_self) strong_self = weak_self;
        AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey] intValue];
        NSLog(@"player status change: %@ %@", @(status), object);
        switch (status) {
            case AVPlayerItemStatusFailed:
                [self.indicatorView stopAnimating];
                break;
            case AVPlayerItemStatusReadyToPlay:
                [self.indicatorView stopAnimating];
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
    self.playerItem = nil;
    [self.delegates.allObjects enumerateObjectsUsingBlock:^(id<FVAVPlayerDelegate>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(playerOnComplete)]) {
            [obj playerOnComplete];
        }
    }];
    
    !self.completionBlock ?: self.completionBlock(self);
}

- (NSString *)vid {
    return ((AVURLAsset *)self.playerItem.asset).URL.lastPathComponent;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.playerLayer.frame = self.bounds;
    self.indicatorView.center = CGPointMake(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0);
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
    return [self.vid isEqualToString:data];
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
    [self loadURL:FVFileURLWithName(data)];
}

- (void)fv_pause {
    [self.player pause];
}

- (void)fv_play {
    self.preloading = NO;
    [self.player play];
}

- (void)fv_preload:(nonnull id)data {
    if (![data isKindOfClass:[NSString class]]) {
        return;
    }
    self.preloading = YES;
    [self loadURL:FVFileURLWithName(data)];
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
