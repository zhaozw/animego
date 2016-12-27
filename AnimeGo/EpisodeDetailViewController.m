//
//  EpisodeDetailViewController.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/3.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "EpisodeDetailViewController.h"
#import "Bangumi+Create.h"
#import "Schedule+Create.h"
#import "AppInstallURL+Create.h"
#import "NetworkConstant.h"
#import "NSDate+Convert.h"
#import "LayoutConstant.h"
#import "NotificationManager.h"
#import "OpenByWebViewController.h"

#define MAS_SHORTHAND
#import "Masonry.h"

@interface EpisodeDetailViewController ()

@property (strong, nonatomic) Schedule *schedule;

@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *statusLabel;
@property (strong, nonatomic) UILabel *captionLabel;
@property (strong, nonatomic) UIButton *openByBrowserButton;
@property (strong, nonatomic) UILabel *openByBrowserLabel;
@property (strong, nonatomic) UIButton *openByAppButton;
@property (strong, nonatomic) UILabel *openByAppLabel;

@end

@implementation EpisodeDetailViewController

#pragma mark - Life Cycle Mothods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.contentView = [[UIView alloc] init];
    [self.view addSubview:self.contentView];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.titleLabel.text = @"正在加载 ...";
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.titleLabel];
    
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.statusLabel];
    
    self.captionLabel = [[UILabel alloc] init];
    self.captionLabel.text = @"在线观看";
    self.captionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.captionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.openByBrowserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.openByBrowserButton addTarget:self
                                action:@selector(touchopenByBrowserButton)
                       forControlEvents:UIControlEventTouchUpInside];
    self.openByBrowserButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.openByBrowserLabel = [[UILabel alloc] init];
    self.openByBrowserLabel.text = @"浏览器";
    self.openByBrowserLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.openByBrowserLabel.translatesAutoresizingMaskIntoConstraints = NO;

    
    self.openByAppButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.openByAppButton addTarget:self
                             action:@selector(touchopenByAppButton)
                   forControlEvents:UIControlEventTouchUpInside];
    self.openByAppButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.openByAppLabel = [[UILabel alloc] init];
    self.openByAppLabel.text = @"客户端";
    self.openByAppLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.openByAppLabel.translatesAutoresizingMaskIntoConstraints = NO;

    [self.contentView makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@0);
        make.top.equalTo(@0);
    }];
    
    [self.titleLabel makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@(LCPadding));
        make.right.lessThanOrEqualTo(@(-LCPadding));
        make.top.equalTo(@(LCPadding));
    }];
    
    [self.statusLabel makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@(LCPadding));
        make.right.lessThanOrEqualTo(@(-LCPadding));
        make.top.equalTo(self.titleLabel.bottom).with.offset(LCPadding);
        make.bottom.lessThanOrEqualTo(@(-LCPadding));
    }];

    self.preferredContentSize = [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateUI];
}

- (void)doJumpToEpisode {
    [self performSegueWithIdentifier:@"Back" sender:self];
}

#pragma mark - Layout Methods

- (void)showCaptionLabel:(BOOL)show {
    if (show && !self.captionLabel.superview) {
        [self.contentView addSubview:self.captionLabel];
        
        [self.captionLabel remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@(LCPadding));
            make.right.lessThanOrEqualTo(@(-LCPadding));
            make.top.equalTo(self.statusLabel.bottom).with.offset(LCPaddingLarge);
            make.bottom.lessThanOrEqualTo(@(-LCPadding));
        }];
    } else if (!show && self.captionLabel.superview) {
        [self.captionLabel removeFromSuperview];
    }
}

- (void)showOpenByBrowserButton:(BOOL)show {
    if (show && !self.openByBrowserButton.superview) {
        [self.contentView addSubview:self.openByBrowserButton];
        [self.contentView addSubview:self.openByBrowserLabel];
        
        [self.openByBrowserButton remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@(LCPadding));
            make.right.lessThanOrEqualTo(@(-LCPadding));
            make.top.equalTo(self.captionLabel.bottom).with.offset(LCPadding);
            make.height.equalTo(@(LCAppIconLength));
            make.width.equalTo(@(LCAppIconLength));
            make.bottom.lessThanOrEqualTo(@(-LCPadding));
        }];
        [self.openByBrowserLabel makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.openByBrowserButton);
            make.right.lessThanOrEqualTo(@(-LCPadding));
            make.top.equalTo(self.openByBrowserButton.bottom).with.offset(LCPadding);
            make.bottom.lessThanOrEqualTo(@(-LCPadding));
        }];
    } else if (!show && self.openByBrowserButton.superview) {
        [self.openByBrowserButton removeFromSuperview];
        [self.openByBrowserLabel removeFromSuperview];
    }
}

- (void)showOpenByAppButton:(BOOL)show {
    if (show && !self.openByAppButton.superview) {
        [self.contentView addSubview:self.openByAppButton];
        [self.contentView addSubview:self.openByAppLabel];
        
        [self.openByAppButton remakeConstraints:^(MASConstraintMaker *make) {
            make.left.greaterThanOrEqualTo(self.openByBrowserButton.right).with.offset(LCPadding);
            make.left.equalTo(@(LCPadding)).priority(500);
            make.top.equalTo(self.captionLabel.bottom).with.offset(LCPadding);
            make.right.lessThanOrEqualTo(@(-LCPadding));
            make.height.equalTo(@(LCAppIconLength));
            make.width.equalTo(@(LCAppIconLength));
            make.bottom.lessThanOrEqualTo(@(-LCPadding));
        }];
        [self.openByAppLabel makeConstraints:^(MASConstraintMaker *make) {
            make.left.greaterThanOrEqualTo(self.openByBrowserLabel.right).with.offset(LCPadding);
            make.centerX.equalTo(self.openByAppButton);
            make.right.lessThanOrEqualTo(@(-LCPadding));
            make.top.equalTo(self.openByAppButton.bottom).with.offset(LCPadding);
            make.bottom.lessThanOrEqualTo(@(-LCPadding));
        }];
    } else if (!show && self.openByAppButton.superview) {
        [self.openByAppButton removeFromSuperview];
        [self.openByAppLabel removeFromSuperview];
    }
}

#pragma mark - Private Methods

- (void)updateWatchedEpisodes {
    [self updateMyProgressWithBangumiId:self.schedule.bangumi.identifier
                             isFavorite:self.schedule.bangumi.isfavorite
                     lastWatchedEpisode:self.schedule.episodenumber
                                success:nil
                        connectionError:nil
                            serverError:nil];
}

- (void)touchopenByBrowserButton {
    [self updateWatchedEpisodes];
    UIViewController *presentingVC = self.presentingViewController;
    [self dismissViewControllerAnimated:NO completion:nil];
    if ([presentingVC isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)presentingVC;
        NSString *urlString = self.schedule.weburl;
        OpenByWebViewController *safariVC = [[OpenByWebViewController alloc] initWithURL:[NSURL URLWithString:urlString]];
        safariVC.navigationController.navigationBarHidden = YES;
        safariVC.modalPresentationStyle = UIModalPresentationFullScreen;
        safariVC.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        UIViewController *bangumiDetailVC = navigationController.topViewController;
        [bangumiDetailVC.navigationController pushViewController:safariVC animated:YES];
    }
}

- (void)touchopenByAppButton {
    UIViewController *presentingVC = self.presentingViewController;
    
    NSString *url = [self convertAppUrl:self.schedule.appurl];
    [self dismissViewControllerAnimated:NO completion:nil];
    if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:url]]){
        NSString *installURL = self.schedule.appinstallurl.installurl;
        if (installURL && ![installURL isEqualToString:@""]
            && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:installURL]]) {
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"该应用尚未安装"
                                                                           message:@"现在可以跳转至 App Store 进行安装"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *installAction = [UIAlertAction actionWithTitle:@"安装"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      [self openURL:installURL];
                                                                  }];
            [alert addAction:installAction];
            
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) { }];
            [alert addAction:cancelAction];
            
            [presentingVC presentViewController:alert animated:YES completion:nil];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"该应用尚未安装"
                                                                           message:@"请选择其他在线观看方式"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"我知道了" style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action) { }];
            [alert addAction:defaultAction];
            [presentingVC presentViewController:alert animated:YES completion:nil];
        }
    } else {
        [self updateWatchedEpisodes];
        [self openURL:url];
    }
}

- (void)openURL:(NSString *)url {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]
                                           options:@{}
                                 completionHandler:nil];
        
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    }
}

#pragma mask - Protected Methods

- (NSFetchRequest *)fetchRequest {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Schedule"];
    request.predicate = [NSPredicate predicateWithFormat:@"(bangumi.identifier == %@) AND (episodenumber == %@)",
                         self.bangumiIdentifier, self.episodeNumber];
    NSSortDescriptor *identifierSort = [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO];
    [request setSortDescriptors:@[identifierSort]];
    return request;
}

- (void)updateUI {
    id object = [[self.fetchedResultsController fetchedObjects] firstObject];
    if (!object || ![object isKindOfClass:[Schedule class]]) return;
    self.schedule = (Schedule *)object;
    
    if (self.schedule.title) {
        self.titleLabel.text = [NSString stringWithFormat:@"第%@集 %@", self.schedule.episodenumber, self.schedule.title];
    } else {
        self.titleLabel.text = [NSString stringWithFormat:@"第%@集", self.schedule.episodenumber];
    }
    
    if (self.schedule) {
        switch (self.schedule.status.integerValue) {
            case AGScheduleStatusNotReleased:
                self.statusLabel.text = [NSString stringWithFormat:@"将于 %@ 更新", [self.schedule.releasedate toString]];
                break;
            case AGScheduleStatusReleased:
                self.statusLabel.text = [NSString stringWithFormat:@"已于 %@ 更新", [self.schedule.releasedate toString]];
                break;
            case AGScheduleStatusCanceled:
                ;
            default:
                ;
        }
        
        BOOL hasBrowserURL = self.schedule.weburl && ![self.schedule.weburl isEqualToString:@""];
        BOOL hasAppURL = self.schedule.appurl && ![self.schedule.appurl isEqualToString:@""];
        [self showCaptionLabel:(hasBrowserURL || hasAppURL)];
        [self showOpenByBrowserButton:hasBrowserURL];
        [self showOpenByAppButton:hasAppURL];
        
        if (hasBrowserURL) {
            self.openByBrowserLabel.text = @"浏览器";
            [self.openByBrowserButton setBackgroundImage:[UIImage imageNamed:@"web"] forState:UIControlStateNormal];
        }
        
        if (hasAppURL) {
            NSString *appURL = [self convertAppUrl:self.schedule.appurl];
            if ([appURL hasPrefix:@"bilibili://"]) {
                self.openByAppLabel.text = @"bilibili";
                [self.openByAppButton setBackgroundImage:[UIImage imageNamed:@"bilibili"] forState:UIControlStateNormal];
            } else if ([appURL hasPrefix:@"youku://"]) {
                self.openByAppLabel.text = @"优酷";
                [self.openByAppButton setBackgroundImage:[UIImage imageNamed:@"youku"] forState:UIControlStateNormal];
            } else if ([appURL hasPrefix:@"youkuhd://"]) {
                self.openByAppLabel.text = @"优酷HD";
                [self.openByAppButton setBackgroundImage:[UIImage imageNamed:@"youku"] forState:UIControlStateNormal];
            } else if ([appURL hasPrefix:@"iqiyi://"]) {
                self.openByAppLabel.text = @"爱奇艺";
                [self.openByAppButton setBackgroundImage:[UIImage imageNamed:@"iqiyi"] forState:UIControlStateNormal];
            } else if ([appURL hasPrefix:@"letvclient://"]) {
                self.openByAppLabel.text = @"乐视视频";
                [self.openByAppButton setBackgroundImage:[UIImage imageNamed:@"letv"] forState:UIControlStateNormal];
            } else if ([appURL hasPrefix:@"ipadletvclient://"]) {
                self.openByAppLabel.text = @"乐视视频HD";
                [self.openByAppButton setBackgroundImage:[UIImage imageNamed:@"letv"] forState:UIControlStateNormal];
            } else {
                self.openByAppLabel.text = @"App";
                [self.openByAppButton setBackgroundImage:[UIImage imageNamed:@"animego"] forState:UIControlStateNormal];
            }
        }
    }
    self.preferredContentSize = [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
}

#pragma mask - Public Properties

- (NSString *)url {
    return self.schedule.weburl;
}

- (NSString *)convertAppUrl:(NSString *)url {
    UIUserInterfaceIdiom deviceType = [[UIDevice currentDevice] userInterfaceIdiom];
    
    if ([url hasPrefix:@"youku://"]) {
        if (deviceType == UIUserInterfaceIdiomPad) {
            url = [url stringByReplacingOccurrencesOfString:@"youku://" withString:@"youkuhd://"];
        }
    } else if ([url hasPrefix:@"letvclient://"]) {
        if (deviceType == UIUserInterfaceIdiomPad) {
            url = [url stringByReplacingOccurrencesOfString:@"letvclient://" withString:@"ipadletvclient://"];
        }
    }
    return url;
}

@end
