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

## 详解
`FeedVideo` 主要由以下部分组成：
#### `FVFeedVideoManager` 
**门面类**，对外提供接口及能力，使用者需要通过初始化该对象来为页面集成播放能力。
1. `playerProvider` 使用者需要实现该接口来提供数据对应的播放器实例，可通过 `FVReusePool` 来集成播放器复用的功能，也可以自定义复用逻辑。
2. `supplier` 需要实现该接口来提供当前页面视图的聚焦检测器 `FVFocusMonitor`，`FVFocusMonitor` 观察了视图的变化，在聚焦的视图发生变化时，来通知 `FVFeedVideoManager` 进行播放器切换，详见 `FVFocusMonitor`
3. `preloadMgr` 可通过实现该接口集成预加载能力，具体详见 `FVPreloadMgrProtocol`
4. 其他属性详见 `FVFeedVideoManager.h`

#### `FVFocusMonitor`
聚焦检测器，它观察了视图的变化，在聚焦的视图发生变化时，发出通知。它由两大部分组成 `FVFocusTrigger` 和 `FVFocusCalculator`。
他们的关系如下图所示：
<img src="https://github.com/wangmchn/Resource/blob/master/FVFocusMonitor.jpg" width="50%">

##### `FVFocusTrigger` 
触发器，负责监听视图变化，并通知 `FVFocusMonitor`。例如 `FVTableViewFocusTrigger/FVCollectionViewFocusTrigger` 分别监听了 `UITableView/UICollectionView` 的滚动/消失以及刷新等事件，如有自定义的视图，可通过继承 `FVFocusTrigger` 来定制自己的触发器。具体内容详见 `FVFocusTrigger` 文件。
#####  `FVFocusCalculator`
计算器，负责计算当前视图层级中，聚焦的视图。例如 `FVCollectionViewFocusCalculator/FVTableViewFocusCalculator` 分别通过遍历 `UICollectionView/UITableView` 的 `visibleCells`, 通过一定的策略得出当前聚焦的视图（例如从上到下第一个灯）。如有自定义的视图，可通过继承 `FVFocusCalculator` 来定制视图的聚焦计算逻辑。具体内容详见 `FVFocusCalculator` 文件。
## License

FeedVideo is available under the MIT license. See the LICENSE file for more info.
