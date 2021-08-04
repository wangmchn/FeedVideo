//
//  FVTikTokViewController.m
//  FeedVideo
//
//  Created by Mark on 2019/10/9.
//  Copyright © 2019 Tencent.Inc. All rights reserved.
//

#import "FVTikTokViewController.h"

@interface FVTikTokViewController ()

@end

@implementation FVTikTokViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.hidesBottomBarWhenPushed = YES;
        self.navigationController.navigationBarHidden = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

@end
