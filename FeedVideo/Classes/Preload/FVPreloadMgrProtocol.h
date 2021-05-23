//
//  FVPreloadMgrProtocol.h
//  FeedVideo
//
//  Created by 王敏 on 2019/10/11.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FVPreloadMgrProtocol <NSObject>
@required
/**
 预加载数据
 @param videoDataList 预加载的数据列表
 */
- (void)fv_preloadVideoDataList:(NSArray *)videoDataList;
@end

NS_ASSUME_NONNULL_END
