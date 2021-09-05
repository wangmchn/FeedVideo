//
//  FVTikTokViewController.m
//  FeedVideo
//
//  Created by Mark on 2019/10/9.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVTikTokViewController.h"
#import "FVPlayerContainerTableViewCell.h"
#import "TestVideoData.h"
#import "FVDebugConfiguration.h"
@import FeedVideo;

@interface FVTikTokViewController () <UITableViewDelegate, UITableViewDataSource, FVPlayerProviderProtocol, FVContainerSupplier, FVFeedVideoManagerDelegate>
@property (nonatomic, strong) FVFeedVideoManager *playerManager;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSString *> *dataList;
@property (nonatomic, strong) FVAVPlayer *inPlayer;

@end

@implementation FVTikTokViewController

- (instancetype)initWithPlayer:(FVAVPlayer *)player {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.inPlayer = player;
    }
    return self;
}

- (void)setUpUI {
    self.title = @"TikTok";
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.pagingEnabled = YES;
    self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.tableView registerClass:[FVPlayerContainerTableViewCell class] forCellReuseIdentifier:NSStringFromClass(FVPlayerContainerTableViewCell.class)];
    [self.view addSubview:self.tableView];
}

- (void)setUpData {
    self.dataList = [[TestVideoData shareInstance] buildTikTokVidListWithInitialVid:self.inPlayer.vid];
}

- (void)setUpPlayerManager {
    self.playerManager = [[FVFeedVideoManager alloc] init];
    self.playerManager.playerProvider = self;
    self.playerManager.supplier = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setUpData];
    [self setUpUI];
    [self setUpPlayerManager];
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

- (FVFocusMonitor *)fv_focusMonitor {
    return [[FVFocusMonitor alloc] initWithTableView:self.tableView];
}

- (id<FVPlayerProtocol>)fv_playerForVideoInfo:(id)videoInfo displayingPlayerList:(NSArray<id<FVPlayerProtocol>> *)playerList {
    return [[FVReusePool sharedInstance] findPlayerRandomlyWithIdentifier:videoInfo type:@"" except:[NSSet setWithArray:playerList]];
}

- (BOOL)fv_canAddPlayerWhenViewWillDisplay:(__kindof UIView *)view {
    return YES;
}

- (NSArray *)fv_playerPreloadListWithFocusView:(UIView *)focusView indexPath:(NSIndexPath *)indexPath {
    if (indexPath.row + 1 < self.dataList.count) {
        return @[self.dataList[indexPath.row + 1]];
    }
    return nil;
}

- (FVContinuePolicy)fv_continuePolicyForPlayingView:(__kindof UIView *)view indexPath:(NSIndexPath *)indexPath {
    return FVContinuePolicyPlayNext;
}

- (FVIndexPathNode *)fv_nextNodeForPlayingView:(__kindof UIView *)view indexPath:(NSIndexPath *)indexPath {
    return FVIndexPathNode.fv_root([NSIndexPath indexPathForRow:indexPath.row + 1 inSection:0]);
}

#pragma mark - UITableViewDataSource & UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FVPlayerContainerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(FVPlayerContainerTableViewCell.class)];
    cell.strURL = self.dataList[indexPath.row];
    cell.textLabel.text = FVDebugConfiguration.uniqueIdentifier;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return tableView.bounds.size.height;
}

@end
