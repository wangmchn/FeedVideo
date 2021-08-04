//
//  FVDebugConfiguration.m
//  FeedVideo
//
//  Created by Mark on 2019/10/9.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVDebugConfiguration.h"

static NSInteger _index;
@implementation FVDebugConfiguration

+ (NSString *)uniqueIdentifier {
    return [NSString stringWithFormat:@"%@", @(++_index)];
}

@end
