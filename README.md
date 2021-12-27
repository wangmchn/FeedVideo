# FeedVideo

[![CI Status](https://img.shields.io/travis/wangmchn@163.com/FeedVideo.svg?style=flat)](https://travis-ci.org/wangmchn@163.com/FeedVideo)
[![Version](https://img.shields.io/cocoapods/v/FeedVideo.svg?style=flat)](https://cocoapods.org/pods/FeedVideo)
[![License](https://img.shields.io/cocoapods/l/FeedVideo.svg?style=flat)](https://cocoapods.org/pods/FeedVideo)
[![Platform](https://img.shields.io/cocoapods/p/FeedVideo.svg?style=flat)](https://cocoapods.org/pods/FeedVideo)

FeedVideo 是一个轻量的页面播放器管理组件，重点解决了在短视频场景中，管理播放器在需要的视图上添加、播放、移除等控制逻辑，并提供了播放的预加载、续播等功能。

业务可通过该组件，快速集成在信息流的播放功能，并通过预加载等功能，拥有优秀的播放体验。

## 示例

1. 运行 `git clone https://github.com/wangmchn/FeedVideo.git`
2. 进入到 Example 目录下，运行 `pod install`
3. 打开 `FeedVideo.xcworkspace` 即可体验示例

## 安装

FeedVideo 支持 [CocoaPods](https://cocoapods.org) 集成，在 Podfile 中添加如下代码即可集成组件：

```ruby
pod 'FeedVideo', :git => 'https://github.com/wangmchn/FeedVideo.git'
```

## 使用
### STEP1. 初始化 FVFeedVideoManager
```objective-c
// 在合适的时机初始化 FVFeedVideoManager，例如在 UI 创建完毕时。
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setUpUI];
    [self setUpPlayerManager];
}

- (void)setUpPlayerManager {
    self.playerManager = [[FVFeedVideoManager alloc] init];
    // 注意，FVFeedVideoManager 需要 supplier 提供 FVFocusMonitor 来监视视图变化，请确保创建时，监视的视图已经初始化
    self.playerManager.supplier = self;
    self.playerManager.playerProvider = self;
    /* 如果需要集成预加载能力，可设置 preloadMgr
    self.playerManager.preloadMgr = [FVPreloadManager shareInstance];
    */
    self.playerManager.delegate = self;
}
```
### STEP2. 实现 FVContainerSupplier && FVPlayerProviderProtocol
```objective-c
#pragma mark - FVContainerSupplier
// 必须实现，需要构建一个 FVFocusMonitor
- (FVFocusMonitor *)fv_focusMonitor {
    // 如使用 UITableView/UICollectionView，组件内部提供了视图的检测能力，可直接初始化对应的 trigger/calculator 初始化 FVFocusMonitor
    // 如没有定制 trigger/calculator 需求，也可直接使用 [[FVFocusMonitor alloc] initWithTableView:self.tableView] / [[FVFocusMonitor alloc] initWithCollectionView:self.collectionView]
    // 如使用自己定义的 view，需自己实现自己视图的 FVFocusTrigger/FVFocusCalculator
    FVTableViewFocusTrigger *trigger = [[FVTableViewFocusTrigger alloc] initWithTableView:self.tableView];
    FVTableViewFocusCalculator *calculator = [[FVTableViewFocusCalculator alloc] initWithRootView:self.tableView];
    calculator.focusPosition = UITableViewScrollPositionTop;
    return [[FVFocusMonitor alloc] initWithTrigger:trigger calculator:calculator];
}

// 可选配置
// 1. FVContinueProtocol 续播相关数据实现，如续播策略，播放结束续播哪个视图等
// 2. FVPreloadProtocol 预加载相关实现，提供对应视图聚焦播放后，需要预加载的数据列表
// 其他可选接口详见：FVContainerSupplier.h

#pragma mark - FVPlayerProviderProtocol
// 提供对应数据的播放器，可使用 FVReusePool 集成复用逻辑
- (id<FVPlayerProtocol>)fv_playerForVideoInfo:(id)videoInfo displayingPlayerList:(NSArray<id<FVPlayerProtocol>> *)playerList {
    return [[FVReusePool sharedInstance] findPlayerRandomlyWithIdentifier:videoInfo type:@"" except:[NSSet setWithArray:playerList]];
}

```
完成以上 `STEP`，`FVFeedVideoManager` 就可以自动在视图刷新，变化时，找到一个合适的 `view` 添加播放器播放。
### 如需指定某个 `view` 播放，可通过以下方式：
1. 在 `UIViewController` 或者其他持有 `FVFeedVideoManager` 的文件，可通过 `FVFeedVideoManager.monitor` 的以下接口来调用，该方式可让不可见的视图聚焦：
```objective-c
/**
 指定对应位置进行播放，可以通过 node.child 来指定嵌套多层的指定播放
 @param node 位置节点
 @param focusType 聚焦方式，是否滚动聚集等，详见 FVFocusType
 @param context 上下文信息，最终会透传给 container
 */
- (void)appointNode:(FVIndexPathNode *)node focusType:(FVFocusType)focusType context:(nullable FVContext *)context;

/**
 举个例子：
 在有嵌套的播放列表时，如需要指定第一个位置中的第二个播放，可以使用如下的调用方式：
 NSIndexPath *root = [NSIndexPath indexPathForRow:0 inSection:0];
 NSIndexPath *child = [NSIndexPath indexPathForRow:1 inSection:0];
 [self.videoManager.monitor appointNode:FVIndexPathNode.fv_root(root).fv_child(child) focusType:FVFocusTypeAfterScroll context:nil];
 */
```
2. 在 `UIView<FVPlayerContainer> */UIView<FVContainerSupplier> *` 内部时，可通过调用 `UIView+Focus.h` 的相关接口：
```objective-c
// 例如在点击该视图时，要使自身聚焦播放：
- (void)didTouchUpInside:(id)sender {
    [self fv_focus];
}
```
## 详解
`FeedVideo` 主要由以下部分组成：
### FVFeedVideoManager
**门面类**，对外提供接口及能力，使用者需要通过初始化该对象来为页面集成播放能力。
1. `playerProvider` 使用者需要实现该接口来提供数据对应的播放器实例，可通过 `FVReusePool` 来集成播放器复用的功能，也可以自定义复用逻辑。
2. `supplier` 需要实现该接口来提供当前页面视图的聚焦检测器 `FVFocusMonitor`，`FVFocusMonitor` 观察了视图的变化，在聚焦的视图发生变化时，来通知 `FVFeedVideoManager` 进行播放器切换，详见 `FVFocusMonitor`
3. `preloadMgr` 可通过实现该接口集成预加载能力，具体详见 `FVPreloadMgrProtocol`
4. 其他属性详见 `FVFeedVideoManager.h`

### FVFocusMonitor
聚焦检测器，它观察了视图的变化，在聚焦的视图发生变化时，发出通知。它由两大部分组成 `FVFocusTrigger` 和 `FVFocusCalculator`。
他们的关系如下图所示：

<img src="https://github.com/wangmchn/Resource/blob/master/FVFocusMonitor.jpg" width="80%">

#### FVFocusTrigger
触发器，负责监听视图变化，并通知 `FVFocusMonitor`。例如 `FVTableViewFocusTrigger/FVCollectionViewFocusTrigger` 分别监听了 `UITableView/UICollectionView` 的滚动/消失以及刷新等事件，如有自定义的视图，可通过继承 `FVFocusTrigger` 来定制自己的触发器。具体内容详见 `FVFocusTrigger` 文件。
#### FVFocusCalculator
计算器，负责计算当前视图层级中，聚焦的视图。例如 `FVCollectionViewFocusCalculator/FVTableViewFocusCalculator` 分别通过遍历 `UICollectionView/UITableView` 的 `visibleCells`, 通过一定的策略得出当前聚焦的视图（例如从上到下第一个灯）。如有自定义的视图，可通过继承 `FVFocusCalculator` 来定制视图的聚焦计算逻辑。具体内容详见 `FVFocusCalculator` 文件。
#### FVContainerSupplier & FVPlayerContainer
`FeedVideo` 的视图层级中由两大类型视图组成 `FVContainerSupplier/FVPlayerContainer`。
`FVPlayerContainer`  即为播放器的容器，当该类型视图聚焦时，播放器将直接被添加到该类型的视图上。
`FVContainerSupplier` 为提供 `FVPlayerContainer` 视图视图，它内部需要含有一个 `FVFocusMonitor`，用于监视他自身的视图聚焦变化，以获取 `FVPlayerContainer` 聚焦的时机。他们的关系如下图所示：

<img src="https://github.com/wangmchn/Resource/blob/master/Supplier%26Container.jpg" width="80%">

#### FVContinueHandler
负责处理续播逻辑，在播放器调用 `Finish` 后，获取下一个需要播放的结点，并使该结点的聚焦。

## License

FeedVideo is available under the MIT license. See the LICENSE file for more info.
