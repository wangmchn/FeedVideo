//
//  FVCollectionViewLayout.h
//  synopsis
//
//  Created by Mark on 2018/3/13.
//  Copyright © 2018年 ghostjiang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FVCollectionViewLayout : UICollectionViewLayout

@property (nonatomic, assign) NSInteger visibleCount;
@property (nonatomic, assign) CGSize itemSize;
@property (nonatomic, assign) CGFloat itemSpacing;
@property (nonatomic, assign) CGFloat topSpacing;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) UIEdgeInsets insets;

@end
