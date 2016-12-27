//
//  OpenByWebViewController.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/22.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "OpenByWebViewController.h"
#import "InsetsLabel.h"
#import "UIColor+ExtraColor.h"
#import "LayoutConstant.h"

#define MAS_SHORTHAND
#import "Masonry.h"

@interface OpenByWebViewController ()

@property (strong, nonatomic) InsetsLabel *thirdPartyWebsiteLabel;

@end

@implementation OpenByWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    self.thirdPartyWebsiteLabel = [[InsetsLabel alloc] init];
    self.thirdPartyWebsiteLabel.insets = UIEdgeInsetsMake(LCPadding / 2, LCPadding, LCPadding / 2, LCPadding);
    self.thirdPartyWebsiteLabel.backgroundColor = [UIColor pinkColor];
    self.thirdPartyWebsiteLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.thirdPartyWebsiteLabel.text = @"正在为您跳转至第三方网站播放…";
    self.thirdPartyWebsiteLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:self.thirdPartyWebsiteLabel];
    
    [self.thirdPartyWebsiteLabel makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_topLayoutGuide).with.offset(64);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
    }];
    
    __weak OpenByWebViewController *weakSelf = self;
    [NSTimer scheduledTimerWithTimeInterval:3.0f
                                    repeats:NO
                                      block:^(NSTimer * _Nonnull timer) {
                                          weakSelf.thirdPartyWebsiteLabel.hidden = YES;
                                      }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
