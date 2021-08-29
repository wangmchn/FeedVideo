//
//  FVIndexPathNode.h
//  FeedVideo
//
//  Created by Mark on 2019/10/10.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FVIndexPathNode : NSObject
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) FVIndexPathNode *child;
@property (nonatomic, readonly, class) FVIndexPathNode *(^fv_root)(NSIndexPath *indexPath);
@property (nonatomic, readonly) FVIndexPathNode *(^fv_child)(NSIndexPath *indexPath);

- (BOOL)isEqualToNode:(nullable FVIndexPathNode *)node;

@end

NS_ASSUME_NONNULL_END
