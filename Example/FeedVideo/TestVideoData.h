//
//  TestVideoData.h
//  VideoFeedsPlay
//
//  Created by 王敏 on 2019/10/10.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TestVideoData : NSObject

+ (instancetype)shareInstance;

@property (nonatomic, readonly) NSString *randomURL;

@end

NS_ASSUME_NONNULL_END
