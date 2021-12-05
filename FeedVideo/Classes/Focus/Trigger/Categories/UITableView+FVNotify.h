//
//  UITableView+FVNotify.h
//  FeedVideo
//
//  Created by Mark on 2019/10/2.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol VFPTableViewNotifyDelegate <NSObject>
@optional

- (void)fv_tableViewDidUpdateData:(UITableView *)tableView;
- (void)fv_tableview:(UITableView *)tableView scrollRectToVisible:(CGRect)rect animated:(BOOL)animated;
- (void)fv_tableview:(UITableView *)tableView setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;

@end

@interface UITableView (FVNotify)
@property (nonatomic, weak, setter=fv_setNotifyDelegate:) id<VFPTableViewNotifyDelegate> fv_notifyDelegate;
@end

NS_ASSUME_NONNULL_END
