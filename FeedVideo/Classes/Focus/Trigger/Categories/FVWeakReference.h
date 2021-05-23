//
//  FVWeakReference.h
//  FeedVideo
//
//  Created by Mark on 2019/10/2.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FVWeakReference : NSObject
@property (nonatomic, weak) id object;
@end

NS_ASSUME_NONNULL_END
