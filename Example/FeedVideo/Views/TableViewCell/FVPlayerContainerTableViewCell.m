//
//  FVPlayerContainerTableViewCell.m
//  VideoFeedsPlay
//
//  Created by Mark on 2019/9/26.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVPlayerContainerTableViewCell.h"
#import "TestVideoData.h"
#import "FVAVPlayer.h"
@import FeedVideo;

@interface FVPlayerContainerTableViewCell () <FVPlayerContainer, FVAVPlayerDelegate>
@property (nonatomic, strong) UILabel *vidLabel;
@end

@implementation FVPlayerContainerTableViewCell

- (UILabel *)vidLabel {
    if (!_vidLabel) {
        _vidLabel = [[UILabel alloc] init];
        _vidLabel.backgroundColor = [UIColor redColor];
        _vidLabel.textColor = [UIColor whiteColor];
        [self.contentView addSubview:_vidLabel];
    }
    return _vidLabel;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [_vidLabel sizeToFit];
    _vidLabel.frame = CGRectMake(10, 20, _vidLabel.frame.size.width, _vidLabel.frame.size.height);
}

- (void)setStrURL:(NSString *)strURL {
    _strURL = strURL;
    self.vidLabel.text = strURL;
    [self setNeedsLayout];
}

#pragma mark - FVPlayerContainer
- (UIView *)fv_playerContainerView {
    return self;
}

- (id)fv_videoInfo {
    return self.strURL;
}

- (NSString *)fv_uniqueIdentifier {
    return self.textLabel.text;
}

- (void)fv_willAddPlayer:(id<FVPlayerProtocol>)player context:(FVContext *)context {
    
}

- (void)fv_didAddPlayer:(id<FVPlayerProtocol>)player context:(FVContext *)context {
    if ([player isKindOfClass:[FVAVPlayer class]]) {
        [((FVAVPlayer *)player) addDelegate:self];
    }
}

- (void)fv_didRemovePlayer:(id<FVPlayerProtocol>)player context:(FVContext *)context {
    if ([player isKindOfClass:[FVAVPlayer class]]) {
        [((FVAVPlayer *)player) removeDelegate:self];
    }
}

#pragma mark - FVAVPlayerDelegate
- (void)playerOnComplete {
    
}

- (void)playerStateChange:(FVPlayerState)state {
    
}

@end
