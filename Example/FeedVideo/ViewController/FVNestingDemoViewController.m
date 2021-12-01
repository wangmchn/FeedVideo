//
//  FVNestingDemoViewController.m
//  FeedVideo
//
//  Created by Mark on 2019/9/26.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVNestingDemoViewController.h"
#import "FVPlayerContainerTableViewCell.h"
#import "FVMonitorSupplierTableViewCell.h"
#import "FVDebugConfiguration.h"
#import "FVPreloadManager.h"
#import "TestVideoData.h"
#import "FVAVPlayer.h"
#import "FVTikTokViewController.h"
@import FeedVideo;

#define FVMonitorSupplierIdentifier NSStringFromClass(FVPlayerContainerTableViewCell.class)
#define FVPlayerContainerIdentifier NSStringFromClass(FVMonitorSupplierTableViewCell.class)
@interface FVNestingDemoViewController () <UITableViewDelegate, UITableViewDataSource, FVPlayerProviderProtocol, FVContainerSupplier, FVFeedVideoManagerDelegate>
@property (nonatomic, strong) FVFeedVideoManager *playerManager;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *dataList;
@end

@implementation FVNestingDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setUpUI];
    [self setUpPlayerManager];
    self.dataList = [[TestVideoData shareInstance] buildNestingDemoVidList];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

#pragma mark - Private
- (void)setUpUI {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.showsHorizontalScrollIndicator = NO;
    
    [self.tableView registerClass:[FVPlayerContainerTableViewCell class] forCellReuseIdentifier:FVPlayerContainerIdentifier];
    [self.tableView registerClass:[FVMonitorSupplierTableViewCell class] forCellReuseIdentifier:FVMonitorSupplierIdentifier];
    [self.view addSubview:self.tableView];
    
    self.title = @"NestingDemo";
}

- (void)setUpPlayerManager {
    self.playerManager = [[FVFeedVideoManager alloc] init];
    self.playerManager.supplier = self;
    self.playerManager.playerProvider = self;
    self.playerManager.preloadMgr = [FVPreloadManager shareInstance];
    self.playerManager.delegate = self;
    [FVReusePool sharedInstance].playerProvider = ^id _Nonnull(NSString * _Nonnull identifier, NSString * _Nonnull type) {
        return [[FVAVPlayer alloc] init];
    };
}

- (NSString *)vidAtIndex:(NSInteger)index offset:(NSInteger)offset {
    NSMutableArray *list = self.dataList.mutableCopy;
    for (NSInteger i = index + 1; i < offset + index; i++) {
        if (i >= list.count) {
            break;
        }
        id value = list[i];
        if ([value isKindOfClass:[NSArray class]]) {
            [list addObjectsFromArray:value];
        }
    }
    if (index + offset >= list.count) {
        return nil;
    }
    return list[index + offset];
}

#pragma mark - FVMonitorSupplierProtocol
- (FVFocusMonitor *)fv_focusMonitor {
    FVTableViewFocusTrigger *trigger = [[FVTableViewFocusTrigger alloc] initWithTableView:self.tableView];
    FVTableViewFocusCalculator *calculator = [[FVTableViewFocusCalculator alloc] initWithRootView:self.tableView];
    calculator.focusPosition = UITableViewScrollPositionTop;
    return [[FVFocusMonitor alloc] initWithTrigger:trigger calculator:calculator];
}

- (FVContinuePolicy)fv_continuePolicyForPlayingView:(__kindof UIView *)view indexPath:(NSIndexPath *)indexPath {
    return FVContinuePolicyRemoveAndPlayNext;
}

- (FVIndexPathNode *)fv_nextNodeForPlayingView:(__kindof UIView *)view indexPath:(NSIndexPath *)indexPath {
    if (indexPath.row + 1 >= self.dataList.count) {
        return nil;
    }
    id nextValue = self.dataList[indexPath.row + 1];
    if ([nextValue isKindOfClass:NSString.class]) {
        return FVIndexPathNode.fv_root([NSIndexPath indexPathForRow:indexPath.row + 1 inSection:0]);
    }
    return FVIndexPathNode.fv_root([NSIndexPath indexPathForRow:indexPath.row + 1 inSection:0]).fv_child([NSIndexPath indexPathForRow:0 inSection:0]);
}

- (NSArray *)fv_dataPreloadListWithFocusView:(UIView *)focusView indexPath:(NSIndexPath *)indexPath {
    return [self buildPreloadListAtIndexPath:indexPath];
}

- (NSArray *)fv_playerPreloadListWithFocusView:(UIView *)focusView indexPath:(NSIndexPath *)indexPath {
    return [self buildPreloadListAtIndexPath:indexPath];
}

- (NSArray *)buildPreloadListAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath) {
        return nil;
    }
    NSString *nextVid = [self vidAtIndex:indexPath.row offset:1];
    if (nextVid.length) {
        return @[nextVid];
    }
    return nil;
}

#pragma mark - FVPlayerProviderProtocol
- (id<FVPlayerProtocol>)fv_playerForVideoInfo:(id)videoInfo displayingPlayerList:(NSArray<id<FVPlayerProtocol>> *)playerList {
    return [[FVReusePool sharedInstance] findPlayerRandomlyWithIdentifier:videoInfo type:@"" except:[NSSet setWithArray:playerList]];
}

#pragma mark - UITableViewDataSource & UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id value = self.dataList[indexPath.row];
    if ([value isKindOfClass:NSArray.class]) {
        FVMonitorSupplierTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FVMonitorSupplierIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.dataList = value;
        return cell;
    }
    FVPlayerContainerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FVPlayerContainerIdentifier];
    cell.textLabel.text = FVDebugConfiguration.uniqueIdentifier;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.strURL = value;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return tableView.frame.size.width / 16.0 * 9;
}

#pragma mark - FVContainerSupplierProtocol
- (BOOL)fv_canAddPlayerWhenViewWillDisplay:(__kindof UIView *)view {
    return NO;
}

@end
