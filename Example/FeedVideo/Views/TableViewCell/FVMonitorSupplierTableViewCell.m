//
//  FVMonitorSupplierTableViewCell.m
//  VideoFeedsPlay
//
//  Created by Mark on 2019/9/26.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVMonitorSupplierTableViewCell.h"
#import "FVCollectionViewLayout.h"
#import "FVPlayerContainerCollectionViewCell.h"
#import "FVDebugConfiguration.h"
#import "TestVideoData.h"
@import FeedVideo;

@interface FVMonitorSupplierTableViewCell () <FVContainerSupplier, UICollectionViewDelegate, UICollectionViewDataSource>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *dataList;
@end

@implementation FVMonitorSupplierTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setUpUI];
        
        self.dataList = [[NSMutableArray alloc] init];
        for (int i = 0; i < 10; i++) {
            [self.dataList addObject:[TestVideoData shareInstance].randomURL];
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    FVCollectionViewLayout *layout = (FVCollectionViewLayout *)self.collectionView.collectionViewLayout;
    layout.itemSize = CGSizeMake(320, 160);
    layout.itemSpacing = 10;
    layout.topSpacing = (self.bounds.size.height - 160) / 2.0;
    CGFloat horizontalInset = (self.bounds.size.width - 320) / 2.0;
    layout.insets = UIEdgeInsetsMake(0, horizontalInset, 0, horizontalInset);
    
    self.collectionView.frame = self.bounds;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.collectionView setContentOffset:CGPointZero];
}

#pragma mark - Private
- (void)setUpUI {
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:[[FVCollectionViewLayout alloc] init]];
    self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = UIColor.whiteColor;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    
    [self.collectionView registerClass:[FVPlayerContainerCollectionViewCell class] forCellWithReuseIdentifier:NSStringFromClass(FVPlayerContainerCollectionViewCell.class)];
    [self.contentView addSubview:self.collectionView];
}

#pragma mark - UICollectionViewDelegate & UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FVPlayerContainerCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(FVPlayerContainerCollectionViewCell.class) forIndexPath:indexPath];
    cell.layer.cornerRadius = 5;
    cell.layer.masksToBounds = YES;
    cell.titlelabel.text = FVDebugConfiguration.uniqueIdentifier;
    if (indexPath.row < self.dataList.count) {
        cell.strURL = [self.dataList objectAtIndex:indexPath.row];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    !self.selectInnerBlock ?: self.selectInnerBlock(indexPath);
}

#pragma mark - FVMonitorSupplierProtocol
- (FVFocusMonitor *)fv_focusMonitor {
    return [[FVFocusMonitor alloc] initWithCollectionView:self.collectionView];
}

- (FVContinuePolicy)fv_continuePolicyForPlayingView:(__kindof UIView *)view indexPath:(NSIndexPath *)indexPath {
    return FVContinuePolicyPlayNext;
}

- (FVIndexPathNode *)fv_nextNodeForPlayingView:(__kindof UIView *)view indexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < 1) {
        return FVIndexPathNode.fv_root([NSIndexPath indexPathForRow:9 inSection:0]);
    }
    return nil;
}

- (NSArray *)fv_dataPreloadListWithFocusView:(UIView *)focusView indexPath:(NSIndexPath *)indexPath {
    if (!indexPath) {
        return nil;
    }
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    if (indexPath.row + 1 < self.dataList.count) {
        [resultArray addObject:[self.dataList objectAtIndex:indexPath.row + 1]];
    }
    
    if (indexPath.row - 1 >= 0 && indexPath.row - 1 < self.dataList.count) {
        [resultArray addObject:[self.dataList objectAtIndex:indexPath.row - 1]];
    }
    return [resultArray copy];
}

- (NSArray *)fv_playerPreloadListWithFocusView:(UIView *)focusView indexPath:(NSIndexPath *)indexPath {
    if (!indexPath) {
        return nil;
    }
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    if (indexPath.row - 1 >= 0 && indexPath.row - 1 < self.dataList.count) {
        [resultArray addObject:[self.dataList objectAtIndex:indexPath.row - 1]];
    }
    
    if (indexPath.row + 1 < self.dataList.count) {
        [resultArray addObject:[self.dataList objectAtIndex:indexPath.row + 1]];
    }
    return [resultArray copy];
}

#pragma mark - VFPContainerSupplierProtocol
- (BOOL)fv_canAddPlayerWhenViewWillDisplay:(__kindof UIView *)view {
    return NO;
}

@end
