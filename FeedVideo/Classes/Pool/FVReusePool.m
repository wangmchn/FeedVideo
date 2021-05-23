//
//  FVReusePool.m
//  FeedVideo
//
//  Created by Mark on 2019/10/7.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVReusePool.h"
#import <UIKit/UIKit.h>

@interface _VFPReuseItem : NSObject
@property (nonatomic, strong) id item;
@property (nonatomic, assign) NSUInteger priority;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *type;
@end

@implementation _VFPReuseItem

- (BOOL)isEqual:(_VFPReuseItem *)object {
    if ([super isEqual:object]) {
        return YES;
    }
    if ([self.identifier isEqualToString:object.identifier] && [self.type isEqualToString:object.type]) {
        return YES;
    }
    return NO;
}

@end

@interface FVReusePool ()
@property (nonatomic, strong) NSMutableSet<_VFPReuseItem *> *pool;
@end

@implementation FVReusePool {
    NSInteger _priority;
}

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (NSUInteger)count {
    return self.pool.count;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _maximumCount = 3;
        _pool = [NSMutableSet set];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)clearPool {
    [self.pool removeAllObjects];
}

- (void)didReceiveMemoryWarning {
    [self clearPool];
}

- (void)setMaximumCount:(NSUInteger)maximumCount {
    _maximumCount = maximumCount;
    NSInteger countToPurge = self.pool.count - maximumCount;
    if (countToPurge <= 0) {
        return;
    }
    // 淘汰多余的
    NSMutableArray<_VFPReuseItem *> *itemsToPurge = self.pool.allObjects.mutableCopy;
    [itemsToPurge sortUsingComparator:^NSComparisonResult(_VFPReuseItem * _Nonnull obj1, _VFPReuseItem * _Nonnull obj2) {
        if (obj1.priority > obj2.priority) {
            return NSOrderedDescending;
        }
        return NSOrderedAscending;
    }];
    [itemsToPurge enumerateObjectsUsingBlock:^(_VFPReuseItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx < countToPurge) {
            [self.pool removeObject:obj];
        }
    }];
}

- (nullable id)abortItemWithIdentifier:(NSString *)identifier type:(NSString *)type {
    NSSet *tmp = self.pool.copy;
    __block _VFPReuseItem *target = nil;
    [tmp enumerateObjectsUsingBlock:^(_VFPReuseItem * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj.identifier isEqualToString:identifier] && [obj.type isEqualToString:type]) {
            [self.pool removeObject:obj];
            target = obj;
            *stop = YES;
        }
    }];
    return target.item;
}

- (BOOL)saveItem:(id)playerItem withIdentifier:(NSString *)identifier type:(NSString *)type {
    if (!playerItem || identifier.length == 0 || type.length == 0) {
        return NO;
    }
    
    __block _VFPReuseItem *target = nil;
    __block _VFPReuseItem *lowest_othertype = nil;
    __block _VFPReuseItem *lowest_sametype = nil;
    NSSet *tmp = self.pool.copy;
    [tmp enumerateObjectsUsingBlock:^(_VFPReuseItem * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj.identifier isEqualToString:identifier] && [obj.type isEqualToString:type]) {
            target = obj;
            *stop = YES;
        } else if ([obj.type isEqualToString:type]) {
            if (!lowest_sametype || obj.priority < lowest_sametype.priority) {
                lowest_sametype = obj;
            }
        } else {
            if (!lowest_othertype || obj.priority < lowest_othertype.priority) {
                lowest_othertype = obj;
            }
        }
    }];
    
    if (target) {
        if (target.item == playerItem) {
            return YES;
        } else {
            [self.pool removeObject:target];
        }
    }
    
    if (self.pool.count >= self.maximumCount) {
        if (lowest_othertype) {
            [self.pool removeObject:lowest_othertype];
        } else if (lowest_sametype) {
            [self.pool removeObject:lowest_sametype];
        }
    }
    _VFPReuseItem *item = [_VFPReuseItem new];
    item.identifier = identifier;
    item.type = type;
    item.item = playerItem;
    item.priority = ++_priority;
    [self.pool addObject:item];
    return YES;
}

- (void)abortUselessItemsForType:(NSString *)type {
    NSSet *tmp = self.pool.copy;
    [tmp enumerateObjectsUsingBlock:^(_VFPReuseItem * _Nonnull obj, BOOL * _Nonnull stop) {
        [self.pool removeObject:obj];
    }];
}

- (id)findPlayerStrictlyWithIdentifier:(NSString *)identifier type:(NSString *)type except:(nullable NSSet *)exceptList {
    __block _VFPReuseItem *target = nil;
    [self.pool enumerateObjectsUsingBlock:^(_VFPReuseItem * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([exceptList containsObject:obj.item]) {
            return;
        }
        if ([obj.identifier isEqualToString:identifier] && [obj.type isEqualToString:type]) {
            target = obj;
            *stop = YES;
        }
    }];
    if (target) {
        target.priority = ++_priority;
        return target.item;
    } else {
        return nil;
    }
}

- (id _Nonnull)createReuseItemAndAddToPool:(NSString * _Nonnull)identifier type:(NSString * _Nonnull)type {
    _VFPReuseItem *item = [_VFPReuseItem new];
    item.identifier = identifier;
    item.type = type;
    item.item = self.playerProvider(identifier, type);
    item.priority = ++_priority;
    [self.pool addObject:item];
    return item.item;
}

- (id)findPlayerRandomlyWithIdentifier:(NSString *)identifier type:(NSString *)type except:(nullable NSSet *)exceptList {
    __block _VFPReuseItem *target = nil;
    __block _VFPReuseItem *lowestPriorityItemOfTargetType = nil;
    __block _VFPReuseItem *lowestPriorityItemOfAll = nil;
    __block BOOL hasTargetType = NO;
    [self.pool enumerateObjectsUsingBlock:^(_VFPReuseItem * _Nonnull obj, BOOL * _Nonnull stop) {
        // 排除exceptList
        if ([exceptList containsObject:obj.item]) {
            return;
        }
        // 找到全局最低优的
        if (!lowestPriorityItemOfAll || obj.priority < lowestPriorityItemOfAll.priority) {
            lowestPriorityItemOfAll = obj;
        }
        // 找到同类型
        if ([obj.type isEqualToString:type]) {
            hasTargetType = YES;
            // 找到同类型中最低优的
            if (!lowestPriorityItemOfTargetType || obj.priority < lowestPriorityItemOfTargetType.priority) {
                lowestPriorityItemOfTargetType = obj;
            }
            // 找到同identifier，并记住，直接返回结果
            if ([obj.identifier isEqualToString:identifier]) {
                target = obj;
                *stop = YES;
            }
        }
    }];
    
    // 1. 命中类型
    // 1.1 identifier相同，直接返回
    if (target) {
        target.priority = ++_priority;
        return target.item;
    }
    
    // 1.2 identifier不同
    // 1.2.1 满池，复用低优
    BOOL poolIsFull = self.pool.count >= self.maximumCount;
    if (hasTargetType) {
        // 1.2 identifier不同
        if (poolIsFull) {
            // 1.2.1 满池，复用同类型最低优
            lowestPriorityItemOfTargetType.identifier = identifier;
            lowestPriorityItemOfTargetType.type = type;
            lowestPriorityItemOfTargetType.priority = ++_priority;
            return lowestPriorityItemOfTargetType.item;
        } else {
            // 1.2.2 不满池，创建
            return [self createReuseItemAndAddToPool:identifier type:type];
        }
    } else {
        // 2. 没有命中类型
        // 2.1 如果满池，移除全局最低优
        if (poolIsFull) {
            [self.pool removeObject:lowestPriorityItemOfAll];
        }
        // 2.2 创建
        return [self createReuseItemAndAddToPool:identifier type:type];
    }
}

- (void)increasePriority:(NSString *)identifier type:(NSString *)type {
    __block _VFPReuseItem *target = nil;
    [self.pool enumerateObjectsUsingBlock:^(_VFPReuseItem * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj.identifier isEqualToString:identifier] && [obj.type isEqualToString:type]) {
            target = obj;
            *stop = YES;
        }
    }];
    target.priority = ++_priority;
}

@end
