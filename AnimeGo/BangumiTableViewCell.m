//
//  BangumiTableViewCell.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/25.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "BangumiTableViewCell.h"

#import "Bangumi+Create.h"
#import "NetworkWorker.h"
#import "LayoutConstant.h"
#import "NetworkConstant.h"
#import "CustomBadgeView.h"
#import "UIColor+ExtraColor.h"
#import "InsetsLabel.h"

#define MAS_SHORTHAND
#import "Masonry.h"

@interface BangumiTableViewCell()

@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) CustomBadgeView *indicator;
@property (nonatomic, strong) InsetsLabel *titleLabel;
@property (nonatomic, strong) InsetsLabel *progressLabel;
@property (nonatomic, strong) UIStackView *stackView;

@end

@implementation BangumiTableViewCell

#pragma mark - UITableViewCell (super class)

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self p_addSubviews];
        [self p_addConstraints];
    }
    return self;
}

#pragma mark - Public Methods

- (void)setSchedule:(Schedule *)schedule {
    _schedule = schedule;
    Bangumi *bangumi = schedule.bangumi;
    self.titleLabel.text = bangumi.title;
    switch (schedule.status.integerValue) {
        case AGScheduleStatusNotReleased:
            self.progressLabel.text = [NSString stringWithFormat:@"第%@话 (未更新)", schedule.episodeNumber];
            break;
        case AGScheduleStatusReleased:
            self.titleLabel.textColor = [UIColor darkTextColor];
            self.progressLabel.textColor = [UIColor darkTextColor];
            switch (schedule.bangumi.status.integerValue) {
                case AGBangumiStatusNotReleased:
                    self.progressLabel.text = @"尚未开播";
                    break;
                case AGBangumiStatusReleased:
                    self.progressLabel.text =
                        [NSString stringWithFormat:@"第%@话 %@", schedule.episodeNumber, schedule.title];
                    break;
                case AGBangumiStatusOver:
                    if (schedule.episodeNumber >= schedule.bangumi.totalEpisodes) {
                        self.progressLabel.text =
                            [NSString stringWithFormat:@"第%@话 %@ (已完结)", schedule.episodeNumber, schedule.title];
                    } else {
                        self.progressLabel.text =
                            [NSString stringWithFormat:@"第%@话 %@", schedule.episodeNumber, schedule.title];
                    }
                    break;
            }
            break;
        case AGScheduleStatusCanceled:
            self.titleLabel.textColor = [UIColor grayColor];
            self.progressLabel.textColor = [UIColor grayColor];
            self.progressLabel.text = [NSString stringWithFormat:@"本周停更"];
            break;
        default:
            ;
    }

    self.titleLabel.textColor = [UIColor whiteColor];
    self.progressLabel.textColor = [UIColor whiteColor];
    
    [[NetworkWorker sharedNetworkWorker] setImageURL:bangumi.coverImageURL forImageView:self.coverImageView];
    
    self.indicator.favorite = schedule.bangumi.isFavorite.boolValue;
    NSInteger releasedEpisodes = schedule.bangumi.lastReleasedEpisode.integerValue;
    NSInteger watchedEpisodes = schedule.bangumi.lastWatchedEpisode.integerValue;
    self.indicator.eventCount = releasedEpisodes - watchedEpisodes;
}

#pragma mark - Private Methods

- (void)p_addSubviews {
    UIView *superView = self.contentView;
    
    self.coverImageView = [[UIImageView alloc] init];
    self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.coverImageView.clipsToBounds = YES;
    [superView addSubview:self.coverImageView];
    
    self.indicator = [[CustomBadgeView alloc] init];
    [superView insertSubview:self.indicator aboveSubview:self.coverImageView];
    
    self.titleLabel = [[InsetsLabel alloc] init];
    self.titleLabel.insets = UIEdgeInsetsMake(LCPadding / 2, LCPadding, LCPadding / 4, LCPadding);
    self.titleLabel.backgroundColor = [UIColor ag_translucentBlackColor];
    self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    [superView addSubview:self.titleLabel];
    
    self.progressLabel = [[InsetsLabel alloc] init];
    self.progressLabel.insets = UIEdgeInsetsMake(LCPadding / 4, LCPadding, LCPadding / 2, LCPadding);
    self.progressLabel.backgroundColor = [UIColor ag_translucentBlackColor];
    self.progressLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    [superView addSubview:self.progressLabel];
}

- (void)p_addConstraints {
    [self.coverImageView remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        make.top.equalTo(@(LCPadding / 2));
        make.bottom.equalTo(@(-LCPadding / 2));
    }];
    
    [self.indicator makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.coverImageView.top).with.offset(LCPadding / 2);
        make.left.equalTo(self.coverImageView.left).with.offset(LCPadding / 2);
    }];
    
    [self.progressLabel makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.coverImageView);
        make.left.equalTo(self.coverImageView);
        make.right.equalTo(self.coverImageView);
    }];
    
    [self.titleLabel makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.progressLabel.top);
        make.left.equalTo(self.coverImageView);
        make.right.equalTo(self.coverImageView);
    }];
}

@end
