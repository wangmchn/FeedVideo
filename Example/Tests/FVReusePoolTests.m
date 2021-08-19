//
//  FVReusePoolTests.m
//  FeedVideo_Tests
//
//  Created by Mark on 2021/8/15.
//  Copyright © 2021 wangmchn@163.com. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface FVReusePool (Test)

@end

@implementation FVReusePool (Test)

- (NSSet *)allItems {
    NSMutableSet *set = [NSMutableSet set];
    [(NSArray *)[self valueForKey:@"pool"] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [set addObject:[obj valueForKey:@"item"]];
    }];
    return set;
}

@end

@interface FVTestPlayer : NSObject
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *identifier;
@end

@implementation FVTestPlayer

@end

NS_INLINE FVTestPlayer *fv_player(NSString *type) {
    FVTestPlayer *player = [[FVTestPlayer alloc] init];
    player.type = type;
    return player;
}

@interface FVReusePoolTests : XCTestCase

@end

@implementation FVReusePoolTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testFindingRandomlyAndNoMatchedPlayers {
    FVReusePool *pool = [[FVReusePool alloc] init];
    XCTAssert(pool.maximumCount == 3);
    __block BOOL blockCalled = NO;
    pool.playerProvider = ^id _Nonnull(NSString * _Nonnull identifier, NSString * _Nonnull type) {
        blockCalled = YES;
        return fv_player(type);
    };

    blockCalled = NO;
    FVTestPlayer *player1 = [pool findPlayerRandomlyWithIdentifier:@"abc" type:@"type1" except:nil];
    XCTAssert([player1.type isEqualToString:@"type1"]);
    XCTAssert(pool.count == 1);
    XCTAssert(blockCalled == YES);
    
    blockCalled = NO;
    FVTestPlayer *player2 = [pool findPlayerRandomlyWithIdentifier:@"xyz" type:@"type2" except:nil];
    XCTAssert([player2.type isEqualToString:@"type2"]);
    XCTAssert(pool.count == 2);
    XCTAssert(blockCalled == YES);
    
    blockCalled = NO;
    FVTestPlayer *player3 = [pool findPlayerRandomlyWithIdentifier:@"123" type:@"type3" except:nil];
    XCTAssert([player3.type isEqualToString:@"type3"]);
    XCTAssert(pool.count == 3);
    XCTAssert(blockCalled == YES);
    // 最大值为 3，再增加类型也没有用了
    blockCalled = NO;
    FVTestPlayer *player4 = [pool findPlayerRandomlyWithIdentifier:@"789" type:@"type4" except:nil];
    XCTAssert([player4.type isEqualToString:@"type4"]);
    XCTAssert(pool.count == 3);
    XCTAssert(blockCalled == YES);
}

- (void)testFindingRandomlyAndTypeMatchedPlayers {
    FVReusePool *pool = [[FVReusePool alloc] init];
    XCTAssert(pool.maximumCount == 3);
    __block BOOL blockCalled = NO;
    pool.playerProvider = ^id _Nonnull(NSString * _Nonnull identifier, NSString * _Nonnull type) {
        blockCalled = YES;
        return fv_player(type);
    };
    [pool findPlayerRandomlyWithIdentifier:@"abc" type:@"type1" except:nil];
    [pool findPlayerRandomlyWithIdentifier:@"xyz" type:@"type2" except:nil];
    XCTAssert(pool.count == 2);
    
    // 当前 pool 个数为 2，< maximumCount, 此时优先从 provider 获取实例
    blockCalled = NO;
    NSSet *items = [pool allItems];
    FVTestPlayer *player = [pool findPlayerRandomlyWithIdentifier:@"exclude_id" type:@"type2" except:nil];
    XCTAssert(blockCalled == YES);
    XCTAssert(pool.count == 3);
    XCTAssert([player.type isEqualToString:@"type2"]);
    XCTAssert(![items containsObject:player]);
    // 当前 pool 个数为 3，== maximumCount, 此时复用池子内的
    blockCalled = NO;
    items = [pool allItems];
    player = [pool findPlayerRandomlyWithIdentifier:@"exclude_id" type:@"type2" except:nil];
    XCTAssert(blockCalled == NO);
    XCTAssert(pool.count == 3);
    XCTAssert([player.type isEqualToString:@"type2"]);
    XCTAssert([items containsObject:player]);
}

- (void)testFindingRandomlyAndTypeIdentifierAllMatchedPlayers {
    FVReusePool *pool = [[FVReusePool alloc] init];
    XCTAssert(pool.maximumCount == 3);
    __block BOOL blockCalled = NO;
    pool.playerProvider = ^id _Nonnull(NSString * _Nonnull identifier, NSString * _Nonnull type) {
        blockCalled = YES;
        FVTestPlayer *player = fv_player(type);
        player.identifier = identifier;
        return player;
    };
    [pool findPlayerRandomlyWithIdentifier:@"abc" type:@"type1" except:nil];
    [pool findPlayerRandomlyWithIdentifier:@"xyz" type:@"type1" except:nil];
    XCTAssert(pool.count == 2);
    
    blockCalled = NO;
    FVTestPlayer *player = [pool findPlayerRandomlyWithIdentifier:@"xyz" type:@"type1" except:nil];
    XCTAssert(blockCalled == NO);
    XCTAssert([player.type isEqualToString:@"type1"]);
    XCTAssert([player.identifier isEqualToString:@"xyz"]);
}

- (void)testFindingRandomlyWithExceptList {
    FVReusePool *pool = [[FVReusePool alloc] init];
    XCTAssert(pool.maximumCount == 3);
    __block BOOL blockCalled = NO;
    pool.playerProvider = ^id _Nonnull(NSString * _Nonnull identifier, NSString * _Nonnull type) {
        blockCalled = YES;
        return fv_player(type);
    };
    [pool findPlayerRandomlyWithIdentifier:@"abc" type:@"type1" except:nil];
    [pool findPlayerRandomlyWithIdentifier:@"xyz" type:@"type1" except:nil];
    XCTAssert(pool.count == 2);
    
    blockCalled = NO;
    NSSet *exceptList = [pool allItems];
    FVTestPlayer *player = [pool findPlayerRandomlyWithIdentifier:@"xyz" type:@"type1" except:exceptList];
    XCTAssert(blockCalled == YES);
    XCTAssert([player.type isEqualToString:@"type1"]);
    XCTAssert(![exceptList containsObject:player]);
}

- (void)testClearPool {
    FVReusePool *pool = [[FVReusePool alloc] init];
    pool.playerProvider = ^id _Nonnull(NSString * _Nonnull identifier, NSString * _Nonnull type) {
        return fv_player(type);
    };
    XCTAssert(pool.maximumCount == 3);
    
    [pool findPlayerRandomlyWithIdentifier:@"abc" type:@"type1" except:nil];
    [pool findPlayerRandomlyWithIdentifier:@"xyz" type:@"type1" except:nil];
    [pool findPlayerRandomlyWithIdentifier:@"123" type:@"type1" except:nil];
    XCTAssert(pool.count == 3);
    
    [pool clearPool];
    XCTAssert(pool.count == 0);
}

- (void)testAbortUselessItemsForTypeIdentifer {
    FVReusePool *pool = [[FVReusePool alloc] init];
    pool.playerProvider = ^id _Nonnull(NSString * _Nonnull identifier, NSString * _Nonnull type) {
        FVTestPlayer *player = fv_player(type);
        player.identifier = identifier;
        return player;
    };
    XCTAssert(pool.maximumCount == 3);
    
    [pool findPlayerRandomlyWithIdentifier:@"abc" type:@"type1" except:nil];
    [pool findPlayerRandomlyWithIdentifier:@"xyz" type:@"type2" except:nil];
    [pool findPlayerRandomlyWithIdentifier:@"123" type:@"type1" except:nil];
    XCTAssert(pool.count == 3);
    
    [pool abortItemWithIdentifier:@"abc" type:@"type1"];
    NSArray *itemsAfterAbort = [pool allItems].allObjects;
    NSInteger index = [itemsAfterAbort indexOfObjectPassingTest:^BOOL(FVTestPlayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj.type isEqualToString:@"type1"] && [obj.identifier isEqualToString:@"abc"];
    }];
    XCTAssert(index == NSNotFound);
}

- (void)testAbortUselessItemsForType {
    FVReusePool *pool = [[FVReusePool alloc] init];
    pool.playerProvider = ^id _Nonnull(NSString * _Nonnull identifier, NSString * _Nonnull type) {
        FVTestPlayer *player = fv_player(type);
        player.identifier = identifier;
        return player;
    };
    XCTAssert(pool.maximumCount == 3);
    
    [pool findPlayerRandomlyWithIdentifier:@"abc" type:@"type1" except:nil];
    [pool findPlayerRandomlyWithIdentifier:@"xyz" type:@"type2" except:nil];
    [pool findPlayerRandomlyWithIdentifier:@"123" type:@"type1" except:nil];
    XCTAssert(pool.count == 3);
    
    [pool abortUselessItemsForType:@"type1"];
    NSArray *itemsAfterAbort = [pool allItems].allObjects;
    NSInteger index = [itemsAfterAbort indexOfObjectPassingTest:^BOOL(FVTestPlayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj.type isEqualToString:@"type1"];
    }];
    XCTAssert(index == NSNotFound);
}

- (void)testFindPlayerStrictly {
    FVReusePool *pool = [[FVReusePool alloc] init];
    pool.playerProvider = ^id _Nonnull(NSString * _Nonnull identifier, NSString * _Nonnull type) {
        FVTestPlayer *player = fv_player(type);
        player.identifier = identifier;
        return player;
    };
    XCTAssert(pool.maximumCount == 3);
    
    [pool findPlayerRandomlyWithIdentifier:@"xyz" type:@"type2" except:nil];
    [pool findPlayerRandomlyWithIdentifier:@"123" type:@"type1" except:nil];
    XCTAssert(pool.count == 2);
    
    {
        FVTestPlayer *player = [pool findPlayerStrictlyWithIdentifier:@"123" type:@"type1" except:nil];
        XCTAssert(player != nil);
        XCTAssert([player.identifier isEqualToString:@"123"]);
        XCTAssert([player.type isEqualToString:@"type1"]);
        XCTAssert(pool.count == 2);
    }

    {
        FVTestPlayer *player = [pool findPlayerStrictlyWithIdentifier:@"xyz" type:@"type1" except:nil];
        XCTAssert(player == nil);
        XCTAssert(pool.count == 2);
    }
    
    {
        FVTestPlayer *player = [pool findPlayerStrictlyWithIdentifier:@"exclude_id" type:@"type1" except:nil];
        XCTAssert(player == nil);
        XCTAssert(pool.count == 2);
    }
    
}

- (void)testIncreasePriority {
    FVReusePool *pool = [[FVReusePool alloc] init];
    pool.playerProvider = ^id _Nonnull(NSString * _Nonnull identifier, NSString * _Nonnull type) {
        FVTestPlayer *player = fv_player(type);
        player.identifier = identifier;
        return player;
    };
    XCTAssert(pool.maximumCount == 3);
    
    [pool findPlayerRandomlyWithIdentifier:@"xyz" type:@"type2" except:nil];
    [pool findPlayerRandomlyWithIdentifier:@"123" type:@"type1" except:nil];
    [pool findPlayerRandomlyWithIdentifier:@"abc" type:@"type3" except:nil];
    XCTAssert(pool.count == 3);

    // 增加 type2 优先级，池子满后，淘汰的不应该是他
    [pool increasePriority:@"xyz" type:@"type2"];
    [pool findPlayerRandomlyWithIdentifier:@"aaa" type:@"type4" except:nil];
    XCTAssert(pool.count == 3);

    NSArray *items = [pool allItems].allObjects;
    NSInteger index = [items indexOfObjectPassingTest:^BOOL(FVTestPlayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj.identifier isEqualToString:@"xyz"] && [obj.type isEqualToString:@"type2"];
    }];
    XCTAssert(index != NSNotFound);
}

- (void)testNotIncreasePriority {
    FVReusePool *pool = [[FVReusePool alloc] init];
    pool.playerProvider = ^id _Nonnull(NSString * _Nonnull identifier, NSString * _Nonnull type) {
        FVTestPlayer *player = fv_player(type);
        player.identifier = identifier;
        return player;
    };
    XCTAssert(pool.maximumCount == 3);
    
    [pool findPlayerRandomlyWithIdentifier:@"xyz" type:@"type2" except:nil];
    [pool findPlayerRandomlyWithIdentifier:@"123" type:@"type1" except:nil];
    [pool findPlayerRandomlyWithIdentifier:@"abc" type:@"type3" except:nil];
    XCTAssert(pool.count == 3);

    // 最先加入的优先级最低，被淘汰
    [pool findPlayerRandomlyWithIdentifier:@"aaa" type:@"type4" except:nil];
    XCTAssert(pool.count == 3);

    NSArray *items = [pool allItems].allObjects;
    NSInteger index = [items indexOfObjectPassingTest:^BOOL(FVTestPlayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj.identifier isEqualToString:@"xyz"] && [obj.type isEqualToString:@"type2"];
    }];
    XCTAssert(index == NSNotFound);
}

@end
