//
//  FVSupplierCandidate.h
//  FeedVideo
//
//  Created by Mark on 2019/10/10.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FVContainerSupplier.h"
#import "FVIndexPathNode.h"
#import "FVFocusMonitor.h"

NS_ASSUME_NONNULL_BEGIN

@interface FVSupplierCandidate : NSObject
@property (nonatomic, strong, readonly) UIView<FVContainerSupplier> *supplier;
@property (nonatomic, strong, readonly) FVIndexPathNode *node;
@property (nonatomic, strong, readonly) FVFocusMonitor *monitor;

- (instancetype)initWithSupplier:(UIView<FVContainerSupplier> *)supplier node:(FVIndexPathNode *)node NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)focusWithType:(FVFocusType)focusType usingBlock:(void(^)(FVSupplierCandidate *candidate, BOOL findNotAuto))completionBlock;

@end

NS_ASSUME_NONNULL_END
