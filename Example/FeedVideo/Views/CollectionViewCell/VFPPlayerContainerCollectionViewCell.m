//
//  FVPlayerContainerCollectionViewCell.m
//  VideoFeedsPlay
//
//  Created by Mark on 2019/9/26.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVPlayerContainerCollectionViewCell.h"
#import "TestVideoData.h"
#import "FVAVPlayer.h"
@import FeedVideo;

@interface FVPlayerContainerCollectionViewCell () <FVPlayerContainer, FVAVPlayerDelegate>
@property (nonatomic, strong) UILabel *vidLabel;
@end

@implementation FVPlayerContainerCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.orangeColor;

        self.titlelabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.titlelabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.titlelabel];
    }
    return self;
}

- (UILabel *)vidLabel {
    if (!_vidLabel) {
        _vidLabel = [[UILabel alloc] init];
        _vidLabel.backgroundColor = [UIColor redColor];
        _vidLabel.textColor = [UIColor whiteColor];
        [self.contentView addSubview:_vidLabel];
    }
    return _vidLabel;
}

- (void)setStrURL:(NSString *)strURL {
    _strURL = strURL;
    self.vidLabel.text = strURL;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.titlelabel.frame = self.bounds;
    
    [self.vidLabel sizeToFit];
    self.vidLabel.frame = CGRectMake(10, 20, self.vidLabel.frame.size.width, self.vidLabel
                                     .frame.size.height);
}

- (UIView *)vfp_playerContainerView {
    return self.contentView;
}

- (id)vfp_videoInfo {
    return self.strURL;
}

- (NSString *)vfp_uniqueIdentifier {
    return self.titlelabel.text;
}

- (BOOL)vfp_isAutoPlay {
    return YES;
}

- (void)vfp_willAddPlayer:(id<VFPPlayerProtocol>)player {
    
}

- (void)vfp_didAddPlayer:(id<VFPPlayerProtocol>)player {
    if ([player isKindOfClass:[FVAVPlayer class]]) {
        [((FVAVPlayer *)player) addDelegate:self];
    }
}

- (void)vfp_didRemovePlayer:(id<VFPPlayerProtocol>)player context:(id)context {
    if ([player isKindOfClass:[FVAVPlayer class]]) {
        [((FVAVPlayer *)player) removeDelegate:self];
    }
}

#pragma mark - FVAVPlayerDelegate
- (void)playerOnComplete {
    
}

- (void)playerStateChange:(VFPPlayerState)state {
    
}

@end
