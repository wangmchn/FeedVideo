//
//  FVIndexPathNode.m
//  FeedVideo
//
//  Created by Mark on 2019/10/10.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVIndexPathNode.h"

@implementation FVIndexPathNode

+ (FVIndexPathNode * _Nonnull (^)(NSIndexPath * _Nonnull))fv_root {
    static FVIndexPathNode *(^fv_root)(NSIndexPath *indexPath);
    if (!fv_root) {
        fv_root = ^FVIndexPathNode *(NSIndexPath *indexPath) {
            NSParameterAssert(indexPath);
            FVIndexPathNode *node = [[FVIndexPathNode alloc] init];
            node.indexPath = indexPath;
            return node;
        };
    }
    return fv_root;
}

- (FVIndexPathNode * _Nonnull (^)(NSIndexPath * _Nonnull))fv_child {
    return ^FVIndexPathNode *(NSIndexPath *indexPath) {
        NSParameterAssert(indexPath);
        FVIndexPathNode *node = [[FVIndexPathNode alloc] init];
        node.indexPath = indexPath;
        FVIndexPathNode *tail = self;
        while (tail.child) {
            tail = tail.child;
        }
        tail.child = node;
        return self;
    };
}

- (NSString *)description {
    NSMutableString *description = @"root".mutableCopy;
    FVIndexPathNode *cursor = self;
    while (cursor) {
        [description appendFormat:@"->%@", cursor.indexPath];
        cursor = cursor.child;
    }
    return description.copy;
}

@end
