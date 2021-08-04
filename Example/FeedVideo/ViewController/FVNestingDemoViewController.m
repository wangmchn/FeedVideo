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
@import FeedVideo;

#define FVMonitorSupplierIdentifier NSStringFromClass(FVPlayerContainerTableViewCell.class)
#define FVPlayerContainerIdentifier NSStringFromClass(FVMonitorSupplierTableViewCell.class)
@interface FVNestingDemoViewController () <UITableViewDelegate, UITableViewDataSource, FVPlayerProviderProtocol, FVContainerSupplier, FVFeedVideoManagerDelegate>
@property (nonatomic, strong) FVFeedVideoManager *playerManager;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataList;
@end

@implementation FVNestingDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setUpUI];
    [self setUpPlayerManager];
    
    [FVReusePool sharedInstance].playerProvider = ^id _Nonnull(NSString * _Nonnull identifier, NSString * _Nonnull type) {
        return [[FVAVPlayer alloc] init];
    };
    
    self.dataList = [[NSMutableArray alloc] init];
    for (int i = 0; i < 100; i++) {
        [self.dataList addObject:[TestVideoData shareInstance].randomURL];
    }
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
    if (indexPath.row < 99) {
        return FVIndexPathNode.fv_root([NSIndexPath indexPathForRow:indexPath.row + 1 inSection:0]);
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
    
    if (indexPath.row + 2 < self.dataList.count) {
        [resultArray addObject:[self.dataList objectAtIndex:indexPath.row + 2]];
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

#pragma mark - FVPlayerProviderProtocol
- (id<FVPlayerProtocol>)fv_playerForVideoInfo:(id)videoInfo exceptPlayerList:(NSArray<id<FVPlayerProtocol>> *)playerList {
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
    if (indexPath.row % 4 == 1) {
        FVMonitorSupplierTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FVMonitorSupplierIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        __weak typeof(self) weak_self = self;
        cell.selectInnerBlock = ^(NSIndexPath * _Nonnull innerIndexPath) {
            [weak_self.playerManager.monitor appointNode:FVIndexPathNode.fv_root(indexPath).fv_child(innerIndexPath) makeFocus:YES context:nil];
        };
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FVPlayerContainerIdentifier];
        cell.textLabel.text = FVDebugConfiguration.uniqueIdentifier;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if (indexPath.row < self.dataList.count) {
            NSString *strURL = [self.dataList objectAtIndex:indexPath.row];
            ((FVPlayerContainerTableViewCell *)cell).strURL = strURL;
        }
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return tableView.frame.size.width / 16.0 * 9;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 点击播放的场景
    [self.playerManager.monitor appointNode:FVIndexPathNode.fv_root(indexPath) makeFocus:YES context:nil];
}

#pragma mark - FVContainerSupplierProtocol
- (BOOL)fv_canAddPlayerWhenViewWillDisplay:(__kindof UIView *)view {
    return NO;
}

@end
