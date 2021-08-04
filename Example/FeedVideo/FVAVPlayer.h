//
//  FVAVPlayer.h
//  VideoFeedExample
//
//  Created by markmwang on 2020/8/26.
//  Copyright © 2020 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@import FeedVideo;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, FVPlayerState) {
    FVPlayerStateNone = 0,
    FVPlayerStateIsPreloading = 1 << 0,
    FVPlayerStateDisappear = 1 << 1,
};

@protocol FVAVPlayerDelegate <NSObject>

@optional
- (void)playerOnComplete;
- (void)playerStateChange:(FVPlayerState)state;

@end

@interface FVAVPlayer : UIView

- (void)addDelegate:(id<FVAVPlayerDelegate>)delegate;
- (void)removeDelegate:(id<FVAVPlayerDelegate>)delegate;

@end

@interface FVAVPlayer (FeedVideo) <FVPlayerProtocol>

@end

NS_ASSUME_NONNULL_END
