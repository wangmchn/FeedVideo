//
//  FVIndexPathNodeTests.m
//  FeedVideo_Tests
//
//  Created by Mark on 2021/8/13.
//  Copyright © 2021 wangmchn@163.com. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface FVIndexPathNodeTests : XCTestCase

@end

@implementation FVIndexPathNodeTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

/// 测试构建 FVIndexPathNode，且链表各个节点的值皆为对应的值
- (void)testCreateIndexPathNode {
    NSIndexPath *root = [NSIndexPath indexPathForRow:0 inSection:0];
    NSIndexPath *child1 = [NSIndexPath indexPathForRow:1 inSection:0];
    NSIndexPath *child2 = [NSIndexPath indexPathForRow:2 inSection:0];
    
    FVIndexPathNode *node = FVIndexPathNode.fv_root(root).fv_child(child1).fv_child(child2);
    // 第 0 个 indexPath 应该为 root
    XCTAssertEqual(node.indexPath, root);
    // 第 1 个 indexPath 应该为 child1
    XCTAssertEqual(node.child.indexPath, child1);
    // 第 2 个 indexPath 应该为 child2
    XCTAssertEqual(node.child.child.indexPath, child2);
    // 第 3 个为 nil
    XCTAssertNil(node.child.child.child);
}

- (void)testIndexPathNodeEqual {
    {
        FVIndexPathNode *node1 = FVIndexPathNode.fv_root([NSIndexPath indexPathForItem:0 inSection:0]).fv_child([NSIndexPath indexPathForRow:1 inSection:0]);
        FVIndexPathNode *node2 = FVIndexPathNode.fv_root([NSIndexPath indexPathForItem:0 inSection:0]).fv_child([NSIndexPath indexPathForRow:1 inSection:0]);
        XCTAssert([node1 isEqualToNode:node2]);
    }
    {
        FVIndexPathNode *node1 = FVIndexPathNode.fv_root([NSIndexPath indexPathForItem:0 inSection:0]).fv_child([NSIndexPath indexPathForRow:1 inSection:0]);
        XCTAssert([node1 isEqualToNode:node1]);
    }
    {
        FVIndexPathNode *node1 = FVIndexPathNode.fv_root([NSIndexPath indexPathForItem:0 inSection:0]).fv_child([NSIndexPath indexPathForRow:1 inSection:0]).fv_child([NSIndexPath indexPathForRow:9 inSection:0]);
        FVIndexPathNode *node2 = FVIndexPathNode.fv_root([NSIndexPath indexPathForItem:0 inSection:0]).fv_child([NSIndexPath indexPathForRow:1 inSection:0]).fv_child([NSIndexPath indexPathForRow:9 inSection:0]);
        XCTAssert([node1 isEqualToNode:node2]);
    }
}

- (void)testIndexPathNodeNotEqual {
    {
        FVIndexPathNode *node1 = FVIndexPathNode.fv_root([NSIndexPath indexPathForItem:0 inSection:0]).fv_child([NSIndexPath indexPathForRow:1 inSection:0]);
        XCTAssert(![node1 isEqualToNode:nil]);
    }
    {
        FVIndexPathNode *node1 = FVIndexPathNode.fv_root([NSIndexPath indexPathForItem:0 inSection:0]).fv_child([NSIndexPath indexPathForRow:1 inSection:0]);
        FVIndexPathNode *node2 = FVIndexPathNode.fv_root([NSIndexPath indexPathForItem:0 inSection:0]).fv_child([NSIndexPath indexPathForRow:2 inSection:0]);
        XCTAssert(![node1 isEqualToNode:node2]);
    }
    {
        FVIndexPathNode *node1 = FVIndexPathNode.fv_root([NSIndexPath indexPathForItem:0 inSection:0]).fv_child([NSIndexPath indexPathForRow:1 inSection:0]);
        FVIndexPathNode *node2 = FVIndexPathNode.fv_root([NSIndexPath indexPathForItem:1 inSection:0]).fv_child([NSIndexPath indexPathForRow:1 inSection:0]);
        XCTAssert(![node1 isEqualToNode:node2]);
    }
    {
        FVIndexPathNode *node1 = FVIndexPathNode.fv_root([NSIndexPath indexPathForItem:0 inSection:0]).fv_child([NSIndexPath indexPathForRow:1 inSection:0]);
        FVIndexPathNode *node2 = FVIndexPathNode.fv_root([NSIndexPath indexPathForItem:0 inSection:0]);
        XCTAssert(![node1 isEqualToNode:node2]);
    }
}

@end
