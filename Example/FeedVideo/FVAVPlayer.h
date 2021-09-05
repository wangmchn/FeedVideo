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

@protocol FVAVPlayerDelegate <NSObject>

@optional
- (void)playerOnComplete;

@end

@interface FVAVPlayer : UIView
@property (nonatomic, readonly) NSString *vid;
@property (nonatomic, assign) BOOL preloading;

- (void)addDelegate:(id<FVAVPlayerDelegate>)delegate;
- (void)removeDelegate:(id<FVAVPlayerDelegate>)delegate;

@end

@interface FVAVPlayer (FeedVideo) <FVPlayerProtocol>

@end

NS_ASSUME_NONNULL_END
