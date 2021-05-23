//
//  FVPlayerContainer.h
//  FeedVideo
//
//  Created by Mark on 2019/9/25.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FVPlayerProtocol.h"
@class FVContext;

NS_ASSUME_NONNULL_BEGIN

/**
 承载播放器的视图容器需要遵循这个协议
 */
@protocol FVPlayerContainer <NSObject>
@required
@property (nonatomic, readonly) UIView *fv_playerContainerView;
@property (nonatomic, readonly) id fv_videoInfo;
@property (nonatomic, readonly) NSString *fv_uniqueIdentifier;

@optional
@property (nonatomic, readonly) BOOL fv_isAutoPlay;
@property (nonatomic, readonly) CGFloat fv_satisfiedVisibleRatio;

- (BOOL)fv_canAddPlayer;

- (void)fv_willAddPlayer:(id<FVPlayerProtocol>)player context:(nullable FVContext *)context;
- (void)fv_didAddPlayer:(id<FVPlayerProtocol>)player context:(nullable FVContext *)context;

- (void)fv_willRemovePlayer:(id<FVPlayerProtocol>)player context:(nullable FVContext *)context;
- (void)fv_didRemovePlayer:(id<FVPlayerProtocol>)player context:(nullable FVContext *)context;

@end

NS_ASSUME_NONNULL_END
