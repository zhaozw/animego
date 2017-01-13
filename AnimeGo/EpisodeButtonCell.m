//
//  EpisodeButtonCell.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/13.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "RoundRectSwitcher.h"

#import "EpisodeButtonCell.h"
#import "LayoutConstant.h"
#import "UIColor+ExtraColor.h"

#define MAS_SHORTHAND
#import "Masonry.h"

@interface EpisodeButtonCell ()

@property (nonatomic, strong) RoundRectSwitcher *button;

@end

@implementation EpisodeButtonCell

#pragma mark - Class Methods

+ (CGSize)calcSize {
    EpisodeButtonCell *testCell = [[EpisodeButtonCell alloc] initWithFrame:CGRectZero];
    [testCell p_initSubview];
    [testCell.button setTitle:@"00" forState:UIControlStateNormal];
    return [testCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
}

#pragma mark - UICollectionViewCell (super class)

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_initSubview];
        self.status = EpisodeButtonCellStatusNotReleased;
    }
    return self;
}

#pragma mark - Privates Methods

- (void)p_initSubview {
    self.button = [[RoundRectSwitcher alloc] init];
    self.button.enabled = NO;
    
    UIUserInterfaceIdiom deviceType = [[UIDevice currentDevice] userInterfaceIdiom];
    UIFont *buttonFont = (deviceType == UIUserInterfaceIdiomPad)
        ? [UIFont systemFontOfSize:[UIFont systemFontSize]]
        : [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    self.button.titleLabel.font = buttonFont;
    self.button.backgroundColor = [UIColor ag_pinkColor];
    [self.button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.contentView addSubview:self.button];
    
    CGFloat minEpisodeButtonWidth = (deviceType == UIUserInterfaceIdiomPad)
        ? LCMinEpisodeButtonWidth
        : LCMinEpisodeButtonWidthPhone;
    [self.button makeConstraints:^(MASConstraintMaker *make) {
        make.width.greaterThanOrEqualTo(@(minEpisodeButtonWidth));
        make.edges.equalTo(self.contentView);
    }];
    [self.button setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                 forAxis:UILayoutConstraintAxisHorizontal];
    [self.button setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                 forAxis:UILayoutConstraintAxisVertical];
}

#pragma mark - Public Methods

- (void)setTitle:(NSString *)title {
    _title = title;
    [self.button setTitle:title forState:UIControlStateNormal];
}

- (void)setStatus:(EpisodeButtonCellStatus)status {
    _status = status;
    switch (status) {
        case EpisodeButtonCellStatusNotReleased:
            self.button.layer.borderColor = [UIColor grayColor].CGColor;
            self.button.layer.borderWidth = 1;
            self.button.backgroundColor = [UIColor whiteColor];
            [self.button setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            break;
        case EpisodeButtonCellStatusReleased:
            self.button.layer.borderColor = [UIColor ag_pinkColor].CGColor;
            self.button.layer.borderWidth = 1;
            self.button.backgroundColor = [UIColor whiteColor];
            [self.button setTitleColor:[UIColor ag_pinkColor] forState:UIControlStateNormal];
            break;
        case EpisodeButtonCellStatusWatched:
            self.button.layer.borderWidth = 0;
            self.button.backgroundColor = [UIColor ag_pinkColor];
            [self.button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
}

@end
