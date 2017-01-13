//
//  BangumiCollectionViewCell.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/29.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "BangumiCollectionViewCell.h"

#import "NetworkWorker.h"
#import "LayoutConstant.h"
#import "NetworkConstant.h"
#import "CustomBadgeView.h"

#define MAS_SHORTHAND
#import "Masonry.h"

@interface BangumiCollectionViewCell ()

@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) CustomBadgeView *indicator;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *statusLabel;

@end

@implementation BangumiCollectionViewCell

#pragma mark - Class Methods

+ (CGSize)calcSizeWithWidth:(CGFloat)width {
    BangumiCollectionViewCell *testCell = [[BangumiCollectionViewCell alloc] initWithFrame:CGRectZero];
    [testCell p_initSubview];
    testCell.titleLabel.text = @"title";
    testCell.statusLabel.text = @"status";
    [testCell.coverImageView makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(width - 2 * LCPadding));
    }];
    return [testCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
}

#pragma mark - UICollectionViewCell (super view)

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_initSubview];
    }
    return self;
}

#pragma mark - Public Methods

- (void)setBangumi:(Bangumi *)bangumi {
    _bangumi = bangumi;
    [[NetworkWorker sharedNetworkWorker] setImageURL:bangumi.coverImageURL forImageView:self.coverImageView];
    self.titleLabel.text = bangumi.title;
    switch (bangumi.status.integerValue) {
        case AGBangumiStatusNotReleased:
            self.statusLabel.text = [NSString stringWithFormat:@"尚未开播"];
            break;
        case AGBangumiStatusReleased:
            self.statusLabel.text = [NSString stringWithFormat:@"已连载至第%@话", bangumi.lastReleasedEpisode];
            break;
        case AGBangumiStatusOver:
            self.statusLabel.text = [NSString stringWithFormat:@"共%@话 (已完结)", bangumi.lastReleasedEpisode];
            break;
    }
    self.indicator.favorite = bangumi.isFavorite.boolValue;
    NSInteger releasedEpisodes = bangumi.lastReleasedEpisode.integerValue;
    NSInteger watchedEpisodes = bangumi.lastWatchedEpisode.integerValue;
    self.indicator.eventCount = releasedEpisodes - watchedEpisodes;
}

#pragma mark - Private Methods

- (void)p_initSubview {
    UIView *superView = self.contentView;
    superView.backgroundColor = nil;
    UIUserInterfaceIdiom deviceType = [[UIDevice currentDevice] userInterfaceIdiom];
    
    self.coverImageView = [[UIImageView alloc] init];
    self.coverImageView.layer.cornerRadius = 5;
    self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.coverImageView.clipsToBounds = YES;
    [superView addSubview:self.coverImageView];
    
    self.indicator = [[CustomBadgeView alloc] init];
    [superView insertSubview:self.indicator aboveSubview:self.coverImageView];
    
    self.titleLabel = [[UILabel alloc] init];
    UIFont *titleLabelFont = (deviceType == UIUserInterfaceIdiomPad)
    ? [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]
    : [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.titleLabel.font = titleLabelFont;
    [superView addSubview:self.titleLabel];
    
    self.statusLabel = [[UILabel alloc] init];
    UIFont *statusLabelFont = (deviceType == UIUserInterfaceIdiomPad)
    ? [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]
    : [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    self.statusLabel.font = statusLabelFont;
    [superView addSubview:self.statusLabel];
    
    [self.coverImageView makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@(LCPadding));
        make.left.equalTo(@(LCPadding));
        make.right.equalTo(@(-LCPadding));
        make.height.equalTo(self.coverImageView.width).multipliedBy(LCCoverImageAspectRatio);
    }];
    
    [self.indicator makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.coverImageView.top).with.offset(LCPadding / 2);
        make.left.equalTo(self.coverImageView.left).with.offset(LCPadding / 2);
    }];
    
    [self.titleLabel makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.coverImageView.bottom).with.offset(LCPadding);
        make.right.equalTo(@(-LCPadding));
        make.left.equalTo(@(LCPadding));
    }];
    
    [self.statusLabel makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.bottom).with.offset(LCPadding / 2);
        make.left.equalTo(@(LCPadding));
        make.right.equalTo(@(-LCPadding));
        make.bottom.equalTo(@(-LCPadding));
    }];
}

@end
