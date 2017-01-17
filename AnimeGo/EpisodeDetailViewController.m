//
//  EpisodeDetailViewController.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/3.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "EpisodeDetailViewController.h"

#import "RoundRectSwitcher.h"
#import "LayoutConstant.h"

#import "NSDate+Format.h"

#import "Bangumi+Create.h"
#import "Schedule+Create.h"
#import "NetworkConstant.h"
#import "NotificationManager.h"
#import "AGRequest.h"

#define MAS_SHORTHAND
#import "Masonry.h"

@interface EpisodeDetailViewController ()

@property (nonatomic, assign) CGSize sizeLimit;
@property (nonatomic, strong) Schedule *schedule;
@property (nonatomic, strong) NSNumber *undoEpisodeNumber;

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) RoundRectSwitcher *markSwitcher;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *captionLabel;
@property (nonatomic, strong) UIButton *openByBrowserButton;
@property (nonatomic, strong) UILabel *openByBrowserLabel;
@property (nonatomic, strong) UIButton *openByAppButton;
@property (nonatomic, strong) UILabel *openByAppLabel;

@end

@implementation EpisodeDetailViewController

#pragma mark - UIViewController (super class)

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self p_addSubviews];
    [self p_addConstraints];
    self.preferredContentSize = [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    
    [[self.markSwitcher.touchSignal
      deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(id  _Nullable x) {
         [self p_touchMarkButton];
     }];
    
    [[[self.openByBrowserButton rac_signalForControlEvents:UIControlEventTouchUpInside]
      deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(__kindof UIControl * _Nullable x) {
         [self p_touchOpenByBrowserButton];
     }];
    
    [[[self.openByAppButton rac_signalForControlEvents:UIControlEventTouchUpInside]
      deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(__kindof UIControl * _Nullable x) {
         [self p_touchOpenByAppButton];
     }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateUI];
}

#pragma mark - FetcherViewController (super class)

- (NSFetchRequest *)fetchRequest {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Schedule"];
    request.predicate = [NSPredicate predicateWithFormat:@"(bangumi.identifier == %@) AND (episodeNumber == %@)",
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
        self.titleLabel.text = [NSString stringWithFormat:@"第%@集 %@", self.schedule.episodeNumber, self.schedule.title];
    } else {
        self.titleLabel.text = [NSString stringWithFormat:@"第%@集", self.schedule.episodeNumber];
    }
    
    if (self.schedule) {
        switch (self.schedule.status.integerValue) {
            case AGScheduleStatusNotReleased:
                self.markSwitcher.hidden = YES;
                self.statusLabel.text = [NSString stringWithFormat:@"将于 %@ 更新", [self.schedule.releaseDate ag_toString]];
                break;
            case AGScheduleStatusReleased:
                self.markSwitcher.hidden = NO;
                self.statusLabel.text = [NSString stringWithFormat:@"已于 %@ 更新", [self.schedule.releaseDate ag_toString]];
                break;
            case AGScheduleStatusCanceled:
                ;
        }
        
        BOOL mark = (self.schedule.episodeNumber.integerValue == self.schedule.bangumi.lastWatchedEpisode.integerValue);
        self.markSwitcher.status = mark;
        self.markSwitcher.enabled = !mark || self.undoEpisodeNumber;
        
        BOOL hasBrowserURL = self.schedule.webURL && ![self.schedule.webURL isEqualToString:@""];
        NSString *appURL = [self.schedule suitableAppURL];
        BOOL canOpenApp = appURL && ![appURL isEqualToString:@""]
        && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:appURL]];
        [self p_showCaptionLabel:(hasBrowserURL || canOpenApp)];
        [self p_showOpenByBrowserButton:hasBrowserURL];
        [self p_showOpenByAppButton:canOpenApp];
        
        if (hasBrowserURL) {
            self.openByBrowserLabel.text = @"浏览器";
            [self.openByBrowserButton setBackgroundImage:[UIImage imageNamed:@"web"] forState:UIControlStateNormal];
        }
        
        if (canOpenApp) {
            if ([appURL hasPrefix:@"bilibili://"]) {
                self.openByAppLabel.text = @"哔哩哔哩动画";
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
            } else if ([appURL hasPrefix:@"pptv://"]) {
                self.openByAppLabel.text = @"聚力视频";
                [self.openByAppButton setBackgroundImage:[UIImage imageNamed:@"pptv"] forState:UIControlStateNormal];
            } else {
                self.openByAppLabel.text = @"App";
                [self.openByAppButton setBackgroundImage:[UIImage imageNamed:@"animego"] forState:UIControlStateNormal];
            }
        }
    }
    self.preferredContentSize = [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
}

- (void)jumpToPage {
    [self performSegueWithIdentifier:@"Back" sender:self];
}

#pragma mark - Private Methods

- (void)p_addSubviews {
    self.contentView = [[UIView alloc] init];
    [self.view addSubview:self.contentView];
    
    self.markSwitcher = [[RoundRectSwitcher alloc] init];
    self.markSwitcher.imageOn = [UIImage imageNamed:@"mark_on"];
    self.markSwitcher.imageOff = [UIImage imageNamed:@"mark_off"];
    [self.contentView addSubview:self.markSwitcher];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.numberOfLines = 1;
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
    self.openByBrowserButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.openByBrowserLabel = [[UILabel alloc] init];
    self.openByBrowserLabel.text = @"浏览器";
    self.openByBrowserLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.openByBrowserLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    
    self.openByAppButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.openByAppButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.openByAppLabel = [[UILabel alloc] init];
    self.openByAppLabel.text = @"客户端";
    self.openByAppLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.openByAppLabel.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)p_addConstraints {
    [self.contentView makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@0);
        make.top.equalTo(@0);
        if (self.sizeLimit.height > 0) make.height.lessThanOrEqualTo(@(self.sizeLimit.height));
        if (self.sizeLimit.width > 0) make.width.lessThanOrEqualTo(@(self.sizeLimit.width));
    }];
    
    [self.markSwitcher makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.titleLabel);
        make.right.lessThanOrEqualTo(@(-LCPadding));
        make.width.equalTo(self.markSwitcher.height);
        make.height.equalTo(self.titleLabel);
    }];
    
    [self.titleLabel makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@(LCPadding));
        make.right.equalTo(self.markSwitcher.left).with.offset(-LCPadding);
        make.top.equalTo(@(LCPadding));
    }];
    
    [self.titleLabel setContentHuggingPriority:UILayoutPriorityRequired
                                       forAxis:UILayoutConstraintAxisVertical];
    
    [self.statusLabel makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@(LCPadding));
        make.right.lessThanOrEqualTo(@(-LCPadding));
        make.top.equalTo(self.titleLabel.bottom).with.offset(LCPadding);
        make.bottom.lessThanOrEqualTo(@(-LCPadding));
    }];
}

- (void)p_showCaptionLabel:(BOOL)show {
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

- (void)p_showOpenByBrowserButton:(BOOL)show {
    if (show && !self.openByBrowserButton.superview) {
        [self.contentView addSubview:self.openByBrowserButton];
        [self.contentView addSubview:self.openByBrowserLabel];
        
        [self.openByBrowserButton remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@(LCPadding));
            make.right.lessThanOrEqualTo(@(-LCPadding));
            make.top.equalTo(self.captionLabel.bottom).with.offset(LCPadding);
            make.bottom.lessThanOrEqualTo(@(-LCPadding));
            make.height.equalTo(@(LCAppIconLength));
            make.width.equalTo(@(LCAppIconLength));
        }];
        [self.openByBrowserLabel remakeConstraints:^(MASConstraintMaker *make) {
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

- (void)p_showOpenByAppButton:(BOOL)show {
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
        [self.openByAppLabel remakeConstraints:^(MASConstraintMaker *make) {
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

- (void)p_updateWatchedEpisodes {
    AGRequest *request = [[AGRequest alloc] init];
    [[request updateMyProgressWithBangumiId:self.schedule.bangumi.identifier
                                 isFavorite:self.schedule.bangumi.isFavorite
                         lastWatchedEpisode:self.schedule.episodeNumber]
     subscribeCompleted:^ { }];
}

- (void)p_touchMarkButton {
    if (self.markSwitcher.status) {
        self.undoEpisodeNumber = self.schedule.bangumi.lastWatchedEpisode;
        [self p_updateWatchedEpisodes];
    } else {
        AGRequest *request = [[AGRequest alloc] init];
        [[request updateMyProgressWithBangumiId:self.schedule.bangumi.identifier
                                     isFavorite:self.schedule.bangumi.isFavorite
                             lastWatchedEpisode:self.undoEpisodeNumber]
         subscribeCompleted:^ { }];
        self.undoEpisodeNumber = nil;
    }
}

- (void)p_touchOpenByBrowserButton {
    NSString *url = self.schedule.webURL;
    [self dismissViewControllerAnimated:NO completion:nil];
    [self p_updateWatchedEpisodes];
    [self p_openURL:url];
}

- (void)p_touchOpenByAppButton {
    NSString *url = [self.schedule suitableAppURL];
    [self dismissViewControllerAnimated:NO completion:nil];
    [self p_updateWatchedEpisodes];
    [self p_openURL:url];
}

- (void)p_openURL:(NSString *)url {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]
                                           options:@{}
                                 completionHandler:nil];
        
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    }
}

#pragma mark - Public Methods

- (instancetype)initWithSizeLimit:(CGSize)sizeLimit {
    self = [super init];
    if (!self) return nil;
    self.sizeLimit = sizeLimit;
    return self;
}

- (NSString *)url {
    return self.schedule.webURL;
}

@end
