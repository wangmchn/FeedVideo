//
//  FVPlayerContainerCollectionViewCell.m
//  FeedVideo
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
        [self.contentView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selfTapped:)]];
    }
    return self;
}

- (void)selfTapped:(id)sender {
    [self fv_focus];
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

- (UIView *)fv_playerContainerView {
    return self.contentView;
}

- (id)fv_videoInfo {
    return self.strURL;
}

- (NSString *)fv_uniqueIdentifier {
    return self.titlelabel.text;
}

- (BOOL)fv_isAutoPlay {
    return YES;
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

@end
