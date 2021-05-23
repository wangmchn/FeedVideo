//
//  FVPreloadProtocol.h
//  FeedVideo
//
//  Created by Mark on 2019/10/11.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FVPreloadProtocol <NSObject>
@optional

/**
 获取需要预加载的数据列表
 @param focusView 当前聚焦的View
 @param indexPath focusView在UI列表中对应的索引
 */
- (nullable NSArray *)fv_dataPreloadListWithFocusView:(UIView *)focusView indexPath:(NSIndexPath *)indexPath;

/**
 获取需要进行播放器层面预加载的数据列表
 @param focusView 当前聚焦的View
 @param indexPath focusView在UI列表中对应的索引
 */
- (nullable NSArray *)fv_playerPreloadListWithFocusView:(UIView *)focusView indexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
