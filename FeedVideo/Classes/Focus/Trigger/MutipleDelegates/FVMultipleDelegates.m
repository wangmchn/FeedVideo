//
//  FVMultipleDelegates.m
//  FeedVideo
//
//  Created by Mark on 2019/9/27.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVMultipleDelegates.h"

static inline void fv_enumerateUsingBlock(NSHashTable *delegates, void (^block)(id delegate, BOOL * _Nonnull stop)) {
    NSArray *delegateList = [delegates allObjects];
    [delegateList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        block(obj, stop);
    }];
}

@interface FVMultipleDelegates ()

@property (nonatomic, strong) NSHashTable *delegates;

@end

@implementation FVMultipleDelegates

- (NSHashTable *)delegates {
    if (!_delegates) {
        _delegates = [NSHashTable weakObjectsHashTable];
    }
    return _delegates;
}

- (void)addDelegate:(id)delegate {
    if (!delegate || [self.delegates containsObject:delegate]) {
        return;
    }
    [self.delegates addObject:delegate];
}

- (void)removeDelegate:(id)delegate {
    if (!delegate || ![self.delegates containsObject:delegate]) {
        return;
    }
    [self.delegates removeObject:delegate];
}

- (BOOL)containsDelegate:(id)aDelegate {
    if (!aDelegate) {
        return NO;
    }
    return [self.delegates containsObject:aDelegate];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    if ([self.mainTarget respondsToSelector:@selector(scrollViewDidScrollToTop:)]) {
        [(id<UIScrollViewDelegate>)self.mainTarget scrollViewDidScrollToTop:scrollView];
    }
    fv_enumerateUsingBlock(self.delegates, ^(id<UIScrollViewDelegate> delegate, BOOL * _Nonnull stop) {
        if ([delegate respondsToSelector:@selector(scrollViewDidScrollToTop:)]) {
            [delegate scrollViewDidScrollToTop:scrollView];
        }
    });
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([self.mainTarget respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [(id<UIScrollViewDelegate>)self.mainTarget scrollViewDidEndDecelerating:scrollView];
    }
    fv_enumerateUsingBlock(self.delegates, ^(id<UIScrollViewDelegate> delegate, BOOL * _Nonnull stop) {
        if ([delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
            [delegate scrollViewDidEndDecelerating:scrollView];
        }
    });
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if ([self.mainTarget respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        [(id<UIScrollViewDelegate>)self.mainTarget scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
    fv_enumerateUsingBlock(self.delegates, ^(id<UIScrollViewDelegate> delegate, BOOL * _Nonnull stop) {
        if ([delegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
            [delegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
        }
    });
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if ([self.mainTarget respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
        [(id<UIScrollViewDelegate>)self.mainTarget scrollViewDidEndScrollingAnimation:scrollView];
    }
    fv_enumerateUsingBlock(self.delegates, ^(id<UIScrollViewDelegate> delegate, BOOL * _Nonnull stop) {
        if ([delegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
            [delegate scrollViewDidEndScrollingAnimation:scrollView];
        }
    });
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([self.mainTarget respondsToSelector:@selector(tableView:willDisplayHeaderView:forSection:)]) {
        [(id<UITableViewDelegate>)self.mainTarget tableView:tableView willDisplayHeaderView:view forSection:section];
    }
    fv_enumerateUsingBlock(self.delegates, ^(id<UITableViewDelegate> delegate, BOOL * _Nonnull stop) {
        if ([delegate respondsToSelector:@selector(tableView:willDisplayHeaderView:forSection:)]) {
            [delegate tableView:tableView willDisplayHeaderView:view forSection:section];
        }
    });
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if ([self.mainTarget respondsToSelector:@selector(tableView:willDisplayFooterView:forSection:)]) {
        [(id<UITableViewDelegate>)self.mainTarget tableView:tableView willDisplayFooterView:view forSection:section];
    }
    fv_enumerateUsingBlock(self.delegates, ^(id<UITableViewDelegate> delegate, BOOL * _Nonnull stop) {
        if ([delegate respondsToSelector:@selector(tableView:willDisplayFooterView:forSection:)]) {
            [delegate tableView:tableView willDisplayFooterView:view forSection:section];
        }
    });
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.mainTarget respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)]) {
        [(id<UITableViewDelegate>)self.mainTarget tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    }
    fv_enumerateUsingBlock(self.delegates, ^(id<UITableViewDelegate> delegate, BOOL * _Nonnull stop) {
        if ([delegate respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)]) {
            [delegate tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
        }
    });
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.mainTarget respondsToSelector:@selector(tableView:didEndDisplayingCell:forRowAtIndexPath:)]) {
        [(id<UITableViewDelegate>)self.mainTarget tableView:tableView didEndDisplayingCell:cell forRowAtIndexPath:indexPath];
    }
    fv_enumerateUsingBlock(self.delegates, ^(id<UITableViewDelegate> delegate, BOOL * _Nonnull stop) {
        if ([delegate respondsToSelector:@selector(tableView:didEndDisplayingCell:forRowAtIndexPath:)]) {
            [delegate tableView:tableView didEndDisplayingCell:cell forRowAtIndexPath:indexPath];
        }
    });
}

- (void)tableView:(UITableView *)tableView didEndDisplayingFooterView:(UIView *)view forSection:(NSInteger)section {
    if ([self.mainTarget respondsToSelector:@selector(tableView:didEndDisplayingFooterView:forSection:)]) {
        [(id<UITableViewDelegate>)self.mainTarget tableView:tableView didEndDisplayingFooterView:view forSection:section];
    }
    fv_enumerateUsingBlock(self.delegates, ^(id<UITableViewDelegate> delegate, BOOL * _Nonnull stop) {
        if ([delegate respondsToSelector:@selector(tableView:didEndDisplayingFooterView:forSection:)]) {
            [delegate tableView:tableView didEndDisplayingFooterView:view forSection:section];
        }
    });
}

- (void)tableView:(UITableView *)tableView didEndDisplayingHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([self.mainTarget respondsToSelector:@selector(tableView:didEndDisplayingHeaderView:forSection:)]) {
        [(id<UITableViewDelegate>)self.mainTarget tableView:tableView didEndDisplayingHeaderView:view forSection:section];
    }
    fv_enumerateUsingBlock(self.delegates, ^(id<UITableViewDelegate> delegate, BOOL * _Nonnull stop) {
        if ([delegate respondsToSelector:@selector(tableView:didEndDisplayingHeaderView:forSection:)]) {
            [delegate tableView:tableView didEndDisplayingHeaderView:view forSection:section];
        }
    });
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.mainTarget respondsToSelector:@selector(collectionView:willDisplayCell:forItemAtIndexPath:)]) {
        [(id<UICollectionViewDelegate>)self.mainTarget collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
    }
    fv_enumerateUsingBlock(self.delegates, ^(id<UICollectionViewDelegate> delegate, BOOL * _Nonnull stop) {
        if ([delegate respondsToSelector:@selector(collectionView:willDisplayCell:forItemAtIndexPath:)]) {
            [delegate collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
        }
    });
}

- (void)collectionView:(UICollectionView *)collectionView willDisplaySupplementaryView:(UICollectionReusableView *)view forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    if ([self.mainTarget respondsToSelector:@selector(collectionView:willDisplaySupplementaryView:forElementKind:atIndexPath:)]) {
        [(id<UICollectionViewDelegate>)self.mainTarget collectionView:collectionView willDisplaySupplementaryView:view forElementKind:elementKind atIndexPath:indexPath];
    }
    fv_enumerateUsingBlock(self.delegates, ^(id<UICollectionViewDelegate> delegate, BOOL * _Nonnull stop) {
        if ([delegate respondsToSelector:@selector(collectionView:willDisplaySupplementaryView:forElementKind:atIndexPath:)]) {
            [delegate collectionView:collectionView willDisplaySupplementaryView:view forElementKind:elementKind atIndexPath:indexPath];
        }
    });
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.mainTarget respondsToSelector:@selector(collectionView:didEndDisplayingCell:forItemAtIndexPath:)]) {
        [(id<UICollectionViewDelegate>)self.mainTarget collectionView:collectionView didEndDisplayingCell:cell forItemAtIndexPath:indexPath];
    }
    fv_enumerateUsingBlock(self.delegates, ^(id<UICollectionViewDelegate> delegate, BOOL * _Nonnull stop) {
        if ([delegate respondsToSelector:@selector(collectionView:didEndDisplayingCell:forItemAtIndexPath:)]) {
            [delegate collectionView:collectionView didEndDisplayingCell:cell forItemAtIndexPath:indexPath];
        }
    });
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    if ([self.mainTarget respondsToSelector:@selector(collectionView:didEndDisplayingSupplementaryView:forElementOfKind:atIndexPath:)]) {
        [(id<UICollectionViewDelegate>)self.mainTarget collectionView:collectionView didEndDisplayingSupplementaryView:view forElementOfKind:elementKind atIndexPath:indexPath];
    }
    fv_enumerateUsingBlock(self.delegates, ^(id<UICollectionViewDelegate> delegate, BOOL * _Nonnull stop) {
        if ([delegate respondsToSelector:@selector(collectionView:didEndDisplayingSupplementaryView:forElementOfKind:atIndexPath:)]) {
            [delegate collectionView:collectionView didEndDisplayingSupplementaryView:view forElementOfKind:elementKind atIndexPath:indexPath];
        }
    });
}

#pragma mark -
- (BOOL)respondsToSelector:(SEL)aSelector {
    BOOL respondsToSelector = [super respondsToSelector:aSelector];
    if (respondsToSelector) {
        return YES;
    }
    return [self.mainTarget respondsToSelector:aSelector];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    BOOL conformsToProtocol = [super conformsToProtocol:aProtocol];
    if (conformsToProtocol) {
        return YES;
    }
    return [self.mainTarget conformsToProtocol:aProtocol];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    return self.mainTarget;
}

// handling unimplemented methods and nil mainTarget
- (void)forwardInvocation:(NSInvocation *)invocation {
    void *nullPointer = NULL;
    [invocation setReturnValue:&nullPointer];
}

// 由于 target 为 weak 引用，且 UIScrollview 会缓存 response 的方法列表，这就意味着在 UIScrollview.delegate 回调的时候，target 可能已经变成 nil 释放了
// 这可能导致 UIScrollView 在不知情的情况下，向转发类发送消息 （原本向 nil 发送消息不会发送危险，但是我们已经将代理替换了）
// 这里有几种方案来解决这个问题：
// 1. hook object dealloc 方法，在 mainTarget 释放的时候，驱动 UIScrollview 更新代理以及方法缓存 (这太重了)
// 2. 实现 -methodSignatureForSelector: & -forwardInvocation:
// 在第二种方法下，这里更好的做法应该是永远返回正确的方法签名，对于大部分第三方组件的实现，会在 -methodSignatureForSelector: 方法中，直接返回 [NSObject instanceMethodSignatureForSelector:@selector(init)];
//      例如：FLAnimatedImage / IGListKit 等，详见：https://github.com/Flipboard/FLAnimatedImage/blob/76a31aefc645cc09463a62d42c02954a30434d7d/FLAnimatedImage/FLAnimatedImage.m#L786-L807
// 对于大部分情况下，这样做是不会有问题的，因为只有没有实现的方法以及 mainTarget == nil 时才会走到这里
// 但是，如果该转发类 (A) 被另一个转发 (B) 类嵌套持有时，且 (B) 直接跳过实现 -forwardingTargetForSelector:，而是通过最后一步 -methodSignatureForSelector: / -forwardInvocation: 来转发事件
//      B 实现 Example:
//      - (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
//           if ([self.mainTarget respondsToSelector:selector]) {
//              return [self.mainTarget methodSignatureForSelector:selector];
//           }
//           return [NSObject instanceMethodSignatureForSelector:@selector(init)];
//      }
//      - (void)forwardInvocation:(NSInvocation *)invocation {
//          if ([self.mainTarget responseToSelector:invocation.selector]) {
//              [invocation invokeWithTarget:self.mainTarget];
//          }
//      }
// 这会导致转发类 (A) 直接跳过 -forwardingTargetForSelector:, 走到 -methodSignatureForSelector:, 从而返回一个错误的方法签名 init (returnValue 为 @，arguments 为 2 个)，从而调用出错
// 这里优化了下上述三方框架的做法, 但仍然无法避免以下情况 A 被 B 嵌套，且 A.mainTarget 是类似 IGListKit / FLAnimatedImage 实现的 Proxy (其中 B 直接跳过了 -forwardingTargetForSelector:，通过最后一步 -methodSignatureForSelector: / -forwardInvocation: 来转发事件)
- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    if ([self.mainTarget respondsToSelector:selector]) {
        return [self.mainTarget methodSignatureForSelector:selector];
    }
    return [NSObject instanceMethodSignatureForSelector:@selector(init)];
}

@end
