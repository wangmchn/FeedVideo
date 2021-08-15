//
//  FVMultipleDelegatesTests.m
//  FeedVideo_Tests
//
//  Created by Mark on 2021/8/13.
//  Copyright © 2021 wangmchn@163.com. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface FVTestDelegateImp : NSObject <UICollectionViewDelegate, UITableViewDelegate, UIScrollViewDelegate>

@end

@implementation FVTestDelegateImp

#pragma mark - Delegate Methods implement in FVMultipleDelegates
- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {}
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {}
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {}
- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {}
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {}
- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {}
- (void)tableView:(UITableView *)tableView didEndDisplayingFooterView:(UIView *)view forSection:(NSInteger)section {}
- (void)tableView:(UITableView *)tableView didEndDisplayingHeaderView:(UIView *)view forSection:(NSInteger)section {}
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {}
- (void)collectionView:(UICollectionView *)collectionView willDisplaySupplementaryView:(UICollectionReusableView *)view forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {}

#pragma mark - Delegate Methods not implement in FVMultipleDelegates
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {}

@end

@interface FVMultipleDelegatesTests : XCTestCase

@end

@implementation FVMultipleDelegatesTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

/// 测试未实现的方法调用不会 crash
- (void)testNoCrash {
    FVMultipleDelegates *multipleDelegates = [[FVMultipleDelegates alloc] init];
    [(UIViewController *)multipleDelegates view];
}

/// 测试代理回调能够正常的回调给 mainTarget/otherDelegates
- (void)testDelegatesCanReceiveEvents {
    FVTestDelegateImp *mainTarget = OCMPartialMock([[FVTestDelegateImp alloc] init]);
    FVTestDelegateImp *otherDelegate = OCMPartialMock([[FVTestDelegateImp alloc] init]);
    FVMultipleDelegates *multipleDelegates = [[FVMultipleDelegates alloc] init];
    multipleDelegates.mainTarget = mainTarget;
    [multipleDelegates addDelegate:otherDelegate];
    // 所有代理方法 mainTarget 能收到所有的方法
    OCMExpect([mainTarget scrollViewDidScroll:OCMOCK_ANY]);
    OCMExpect([mainTarget tableView:OCMOCK_ANY didSelectRowAtIndexPath:OCMOCK_ANY]);
    OCMExpect([mainTarget collectionView:OCMOCK_ANY didSelectItemAtIndexPath:OCMOCK_ANY]);
    
    OCMExpect([mainTarget scrollViewDidScrollToTop:OCMOCK_ANY]);
    OCMExpect([mainTarget scrollViewDidEndDecelerating:OCMOCK_ANY]);
    OCMExpect([mainTarget scrollViewDidEndDragging:OCMOCK_ANY willDecelerate:OCMOCK_ANY]).ignoringNonObjectArgs;
    OCMExpect([mainTarget scrollViewDidEndScrollingAnimation:OCMOCK_ANY]);
    OCMExpect([mainTarget tableView:OCMOCK_ANY willDisplayCell:OCMOCK_ANY forRowAtIndexPath:OCMOCK_ANY]);
    OCMExpect([mainTarget tableView:OCMOCK_ANY didEndDisplayingCell:OCMOCK_ANY forRowAtIndexPath:OCMOCK_ANY]);
    OCMExpect([mainTarget collectionView:OCMOCK_ANY willDisplayCell:OCMOCK_ANY forItemAtIndexPath:OCMOCK_ANY]);
    OCMExpect([mainTarget collectionView:OCMOCK_ANY didEndDisplayingCell:OCMOCK_ANY forItemAtIndexPath:OCMOCK_ANY]);
    
    // otherDelegate 不应该收到不需要的回调
    OCMReject([otherDelegate scrollViewDidScroll:OCMOCK_ANY]);
    OCMReject([otherDelegate tableView:OCMOCK_ANY didSelectRowAtIndexPath:OCMOCK_ANY]);
    OCMReject([otherDelegate collectionView:OCMOCK_ANY didSelectItemAtIndexPath:OCMOCK_ANY]);
    // otherDelegate 可以收到需要的回调
    OCMExpect([otherDelegate scrollViewDidScrollToTop:OCMOCK_ANY]);
    OCMExpect([otherDelegate scrollViewDidEndDecelerating:OCMOCK_ANY]);
    OCMExpect([otherDelegate scrollViewDidEndDragging:OCMOCK_ANY willDecelerate:OCMOCK_ANY]).ignoringNonObjectArgs;
    OCMExpect([otherDelegate scrollViewDidEndScrollingAnimation:OCMOCK_ANY]);
    OCMExpect([otherDelegate tableView:OCMOCK_ANY willDisplayCell:OCMOCK_ANY forRowAtIndexPath:OCMOCK_ANY]);
    OCMExpect([otherDelegate tableView:OCMOCK_ANY didEndDisplayingCell:OCMOCK_ANY forRowAtIndexPath:OCMOCK_ANY]);
    OCMExpect([otherDelegate collectionView:OCMOCK_ANY willDisplayCell:OCMOCK_ANY forItemAtIndexPath:OCMOCK_ANY]);
    OCMExpect([otherDelegate collectionView:OCMOCK_ANY didEndDisplayingCell:OCMOCK_ANY forItemAtIndexPath:OCMOCK_ANY]);
    
    // 调用
    if ([multipleDelegates respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [multipleDelegates scrollViewDidScroll:OCMOCK_ANY];
    }
    if ([multipleDelegates respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
        [multipleDelegates tableView:OCMOCK_ANY didSelectRowAtIndexPath:OCMOCK_ANY];
    }
    if ([multipleDelegates respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)]) {
        [multipleDelegates collectionView:OCMOCK_ANY didSelectItemAtIndexPath:OCMOCK_ANY];
    }
    if ([multipleDelegates respondsToSelector:@selector(scrollViewDidScrollToTop:)]) {
        [multipleDelegates scrollViewDidScrollToTop:OCMOCK_ANY];
    }
    if ([multipleDelegates respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [multipleDelegates scrollViewDidEndDecelerating:OCMOCK_ANY];
    }
    if ([multipleDelegates respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        [multipleDelegates scrollViewDidEndDragging:OCMOCK_ANY willDecelerate:YES];
    }
    if ([multipleDelegates respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
        [multipleDelegates scrollViewDidEndScrollingAnimation:OCMOCK_ANY];
    }
    if ([multipleDelegates respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)]) {
        [multipleDelegates tableView:OCMOCK_ANY willDisplayCell:OCMOCK_ANY forRowAtIndexPath:OCMOCK_ANY];
    }
    if ([multipleDelegates respondsToSelector:@selector(tableView:didEndDisplayingCell:forRowAtIndexPath:)]) {
        [multipleDelegates tableView:OCMOCK_ANY didEndDisplayingCell:OCMOCK_ANY forRowAtIndexPath:OCMOCK_ANY];
    }
    if ([multipleDelegates respondsToSelector:@selector(collectionView:willDisplayCell:forItemAtIndexPath:)]) {
        [multipleDelegates collectionView:OCMOCK_ANY willDisplayCell:OCMOCK_ANY forItemAtIndexPath:OCMOCK_ANY];
    }
    if ([multipleDelegates respondsToSelector:@selector(collectionView:didEndDisplayingCell:forItemAtIndexPath:)]) {
        [multipleDelegates collectionView:OCMOCK_ANY didEndDisplayingCell:OCMOCK_ANY forItemAtIndexPath:OCMOCK_ANY];
    }
}

@end
