//
//  BangumiDetailViewController.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/26.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "BangumiDetailViewController.h"

#import "EpisodeDetailViewController.h"
#import "EpisodeButtonCell.h"
#import "RoundRectSwitcher.h"
#import "LayoutConstant.h"

#import "NSDate+Format.h"
#import "NSString+Append.h"
#import "UIColor+ExtraColor.h"

#import "Schedule+Create.h"
#import "NotificationManager.h"
#import "NetworkWorker.h"
#import "NetworkConstant.h"
#import "AGRequest.h"

#define MAS_SHORTHAND
#import "Masonry.h"

static NSString * const kReuseIdentifier = @"Cell";

@interface BangumiDetailViewController ()

@property (nonatomic, strong) Bangumi *bangumi;

@property (nonatomic, strong) RoundRectSwitcher *showDetailButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIScrollView *detailView;
@property (nonatomic, strong) UILabel *stuffLabel;
@property (nonatomic, strong) UILabel *cvLabel;
@property (nonatomic, strong) UILabel *synopsisLabel;
@property (nonatomic, strong) UIView *separationLine;
@property (nonatomic, strong) RoundRectSwitcher *showEpisodeTitleButton;
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, strong) UICollectionView *episodeButtonsView;

@property (nonatomic, strong) UIImageView *largeImageView;
@property (nonatomic, strong) UILabel *captionLabel;
@property (nonatomic, strong) RoundRectSwitcher *favoriteButton;

@property (nonatomic, strong) NSMutableDictionary *episodeDict;
@property (nonatomic, assign) NSInteger firstReleasedEpisode;
@property (nonatomic, assign) NSInteger lastReleasedEpisode;
@property (nonatomic, assign) NSInteger lastWatchedEpisode;
@property (nonatomic, assign) NSInteger totalEpisodes;

@end

@implementation BangumiDetailViewController

#pragma mark - UIViewController (super class)

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.firstReleasedEpisode = -1;
    self.lastReleasedEpisode = -1;
    self.lastWatchedEpisode = -1;
    self.totalEpisodes = -1;
    
    [self p_addSubviews];
    [self p_addConstraints];
    
    [[self.favoriteButton.touchSignal
      deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(id  _Nullable x) {
         [self p_touchFavoriteButton];
     }];
    
    [[self.showDetailButton.touchSignal
      deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(id  _Nullable x) {
         [self p_touchShowDetailButton];
     }];
    
    [[self.showEpisodeTitleButton.touchSignal
      deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(id  _Nullable x) {
         [self p_touchShowEpisodeTitleButton];
     }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSSet *episodesSet = self.bangumi.schedule;
    for (Schedule *schedule in episodesSet) {
        [self.episodeDict setObject:schedule.title forKey:@(schedule.episodeNumber.integerValue)];
    }
    [self updateUI];
    
    AGRequest *request = [[AGRequest alloc] init];
    [[[request fetchListAllEpisodesWithBangumiId:self.bangumi.identifier]
      deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(NSArray *result) {
         for (NSDictionary *scheduleDict in result) {
             NSNumber *episodeNumber = [scheduleDict valueForKey:AGScheduleKeyEpisodeNumber];
             NSString *title = [scheduleDict valueForKey:AGScheduleKeyTitle];
             [self.episodeDict setObject:title forKey:@(episodeNumber.integerValue)];
         }
         self.showEpisodeTitleButton.imageOn = [UIImage imageNamed:@"show_episode_title_on"];
         [self.episodeButtonsView reloadData];
     }];
}

#pragma mark - FetcherViewController (super class)

- (void)didBecomeActive {
    [super didBecomeActive];
    [self.episodeButtonsView reloadData];
}

- (void)doJumpToEpisode {
    [self performSegueWithIdentifier:@"Back" sender:self];
}

- (void)fetchRemoteData {
    if (!self.bangumiIdentifier) return;
    AGRequest *request = [[AGRequest alloc] init];
    [[request fetchBangumiDetailWithBangumiId:self.bangumiIdentifier] subscribeCompleted:^{ }];
}

- (void)updateUI {
    if (!self.fetchedResultsController) return;
    id object = [[self.fetchedResultsController fetchedObjects] firstObject];
    if (!object || ![object isKindOfClass:[Bangumi class]]) return;
    self.bangumi = (Bangumi *)object;
    
    self.navigationItem.title = self.bangumi.title;
    self.titleLabel.text = self.bangumi.title;
    if (self.bangumi.stuff) {
        self.stuffLabel.text = [NSString stringWithFormat:@"制作人员: %@", self.bangumi.stuff];
    }
    if (self.bangumi.characterVoice) {
        self.cvLabel.text = [NSString stringWithFormat:@"主要声优: %@", self.bangumi.characterVoice];
    }
    if (self.bangumi.synopsis) {
        self.synopsisLabel.text = self.bangumi.synopsis;
    }
    self.favoriteButton.status = [self.bangumi.isFavorite isEqual:@(YES)];
    
    [[NotificationManager sharedNotificationManager] getNotificationSettingsWithCompletionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self p_updateCaptionLabel];
        });
    }];
    
    NSInteger firstReleasedEpisode = (self.bangumi.firstReleasedEpisode).integerValue;
    NSInteger lastReleasedEpisode = (self.bangumi.lastReleasedEpisode).integerValue;
    NSInteger lastWatchedEpisode = (self.bangumi.lastWatchedEpisode).integerValue;
    NSInteger totalEpisodes = (self.bangumi.totalEpisodes).integerValue;
    
    if (self.bangumi.status.integerValue == AGBangumiStatusOver) {
        self.progressLabel.text = [NSString stringWithFormat:@"共%ld集 (已完结)", (long)lastReleasedEpisode];
    } else {
        NSString *progressLabelText = @"";
        
        NSString *releaseWeekdayString = @"";
        NSInteger releaseWeekday = (self.bangumi.releaseWeekday).integerValue;
        if (releaseWeekday > 0 && releaseWeekday < [[NSDate ag_weekdayNameArray] count]) {
            releaseWeekdayString = [NSString stringWithFormat:@"%@更新", [NSDate ag_weekdayNameArray][releaseWeekday]];
        }
        progressLabelText = [progressLabelText ag_stringByAppendingStringWithComma:releaseWeekdayString];
        
        NSString *lastWatchedString = @"";
        if (lastWatchedEpisode >= firstReleasedEpisode) {
            lastWatchedString = [NSString stringWithFormat:@"上次看到第%ld集", (long)lastWatchedEpisode];
        }
        progressLabelText = [progressLabelText ag_stringByAppendingStringWithComma:lastWatchedString];
        
        NSString *lastReleasedString = [NSString stringWithFormat:@"已更新至第%ld集", (long)lastReleasedEpisode];
        if (lastReleasedEpisode == 0) {
            lastReleasedString = @"尚未开播";
            for (Schedule *episode in self.bangumi.schedule) {
                if (episode.episodeNumber.integerValue == firstReleasedEpisode) {
                    lastReleasedString = [NSString stringWithFormat:@"%@开播", [episode.releaseDate ag_toString]];
                    break;
                }
            }
        }
        progressLabelText = [progressLabelText ag_stringByAppendingStringWithComma:lastReleasedString];
        
        self.progressLabel.text = progressLabelText;
    }
    
    [[NetworkWorker sharedNetworkWorker] setImageURL:self.bangumi.largeImageURL forImageView:self.largeImageView];
    
    if ((self.firstReleasedEpisode >= 0 && self.firstReleasedEpisode != firstReleasedEpisode)
        || (self.lastReleasedEpisode >= 0 && self.lastReleasedEpisode != lastReleasedEpisode)
        || (self.lastWatchedEpisode >= 0 && self.lastWatchedEpisode != lastWatchedEpisode)
        || (self.totalEpisodes >= 0 && self.totalEpisodes != totalEpisodes)) {
        
        [self.episodeButtonsView reloadData];
    }
    
    self.firstReleasedEpisode = firstReleasedEpisode;
    self.lastReleasedEpisode = lastReleasedEpisode;
    self.lastWatchedEpisode = lastWatchedEpisode;
    self.totalEpisodes = totalEpisodes;
}

- (NSFetchRequest *)fetchRequest {
    if (!self.bangumiIdentifier) return nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Bangumi"];
    request.predicate = [NSPredicate predicateWithFormat:@"identifier == %@", self.bangumiIdentifier];
    NSSortDescriptor *identifierSort = [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO];
    [request setSortDescriptors:@[identifierSort]];
    return request;
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger totalEpisodes = (self.bangumi.totalEpisodes).integerValue;
    NSInteger firstReleasedEpisoed = (self.bangumi.firstReleasedEpisode).integerValue;
    if (totalEpisodes <= 0) return 0;
    return totalEpisodes - firstReleasedEpisoed + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kReuseIdentifier
                                                                           forIndexPath:indexPath];
    
    if ([cell isKindOfClass:[EpisodeButtonCell class]]) {
        EpisodeButtonCell *episodeButtonCell = (EpisodeButtonCell *)cell;
        NSInteger firstReleasedEpisode = (self.bangumi.firstReleasedEpisode).integerValue;
        NSInteger lastReleasedEpisode = (self.bangumi.lastReleasedEpisode).integerValue;
        NSInteger lastWatchedEpisode = (self.bangumi.lastWatchedEpisode).integerValue;
        NSInteger episodeNumber = indexPath.row + firstReleasedEpisode;
        NSString *title = [NSString stringWithFormat:@"%ld", (long)episodeNumber];
        if (self.showEpisodeTitleButton.status) {
            NSString *episodeTitle = self.episodeDict[@(episodeNumber)];
            if (episodeTitle && ![episodeTitle isEqualToString:@""]) {
                title = [NSString stringWithFormat:@"%@ %@", title, episodeTitle];
            }
        }
        episodeButtonCell.title = title;
        if (episodeNumber <= lastWatchedEpisode) {
            episodeButtonCell.status = EpisodeButtonCellStatusWatched;
        } else if (episodeNumber <= lastReleasedEpisode) {
            episodeButtonCell.status = EpisodeButtonCellStatusReleased;
        } else {
            episodeButtonCell.status = EpisodeButtonCellStatusNotReleased;
        }
    }
    return cell;
}

#pragma mark - <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    if ([cell isKindOfClass:[EpisodeButtonCell class]]) {
        EpisodeButtonCell *episodeButtonCell = (EpisodeButtonCell *)cell;
        NSInteger episodeNumber = indexPath.row + self.bangumi.firstReleasedEpisode.integerValue;
        
        AGRequest *request = [[AGRequest alloc] init];
        [[request fetchEpisodeDetailWithBangumiId:self.bangumi.identifier
                                   episodeNumber:@(episodeNumber)]
         subscribeCompleted:^{ }];

        EpisodeDetailViewController *episodeDetailVC = [[EpisodeDetailViewController alloc] init];
        episodeDetailVC.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *popoverPC = episodeDetailVC.popoverPresentationController;
        popoverPC.backgroundColor = [UIColor lightGrayColor];
        popoverPC.sourceView = episodeButtonCell;
        popoverPC.sourceRect = episodeButtonCell.contentView.bounds;
        popoverPC.delegate = self;
        
        episodeDetailVC.bangumiIdentifier = self.bangumiIdentifier;
        episodeDetailVC.episodeNumber = @(episodeNumber);
        
        [self presentViewController:episodeDetailVC animated:YES completion:nil];
    }
}

#pragma mark - <UIPopoverPresentControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
                                                               traitCollection:(UITraitCollection *)traitCollection {
    
    return UIModalPresentationNone;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

#pragma mark - Private Methods

- (NSMutableDictionary *)episodeDict {
    if (!_episodeDict) _episodeDict = [[NSMutableDictionary alloc] init];
    return _episodeDict;
}

- (void)p_touchShowDetailButton {
    UIView *superView = self.view;
    UIUserInterfaceIdiom deviceType = [[UIDevice currentDevice] userInterfaceIdiom];
    CGFloat padding = LCPadding;
    CGFloat paddingLarge = (deviceType == UIUserInterfaceIdiomPad) ? LCPaddingLarge : LCPadding;
    
    if (self.showDetailButton.status) {
        [self.view addSubview:self.detailView];
        [self.detailView remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.titleLabel.bottom).with.offset(paddingLarge);
            make.left.equalTo(@(paddingLarge));
            make.right.equalTo(self.largeImageView.left).with.offset(-paddingLarge * 2);
            make.height.equalTo(superView).multipliedBy(0.4);
        }];
        [self.stuffLabel remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@0);
            make.left.equalTo(superView).with.offset(paddingLarge);
            make.right.equalTo(self.largeImageView.left).with.offset(-paddingLarge * 2);
        }];
        [self.cvLabel remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.stuffLabel.bottom).with.offset(padding);
            make.left.equalTo(superView).with.offset(paddingLarge);
            make.right.equalTo(self.largeImageView.left).with.offset(-paddingLarge * 2);
        }];
        
        [self.synopsisLabel remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.cvLabel.bottom).with.offset(paddingLarge);
            make.left.equalTo(superView).with.offset(paddingLarge);
            make.right.equalTo(self.largeImageView.left).with.offset(-paddingLarge * 2);
            make.bottom.equalTo(@0);
        }];
        
        [self.separationLine remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.detailView.bottom).with.offset(padding);
            make.left.equalTo(@(paddingLarge));
            make.right.equalTo(self.largeImageView.left).with.offset(-paddingLarge * 2);
            make.height.equalTo(@1);
        }];
    } else {
        [self.detailView removeFromSuperview];
        [self.separationLine remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.titleLabel.bottom).with.offset(padding);
            make.left.equalTo(@(paddingLarge));
            make.right.equalTo(self.largeImageView.left).with.offset(-paddingLarge * 2);
            make.height.equalTo(@1);
        }];
    }
}

- (void)p_touchShowEpisodeTitleButton {
    [self.episodeButtonsView reloadData];
}

- (void)p_touchFavoriteButton {
    NSNumber *isFavorite = self.favoriteButton.status ? @(YES) : @(NO);
    
    AGRequest *request = [[AGRequest alloc] init];
    [[request updateMyProgressWithBangumiId:self.bangumiIdentifier
                                 isFavorite:isFavorite
                         lastWatchedEpisode:self.bangumi.lastWatchedEpisode]
     subscribeCompleted:^{ }];
}

- (void)p_updateCaptionLabel {
    if (self.bangumi.status.integerValue == AGBangumiStatusOver) {
        self.captionLabel.text = @"动画已完结";
    } else {
        if ([self.bangumi.isFavorite isEqual:@(YES)]) {
            if ([NotificationManager sharedNotificationManager].enable) {
                self.captionLabel.text = @"动画已收藏, 新的集数一旦更新, 将会立即推送给您";
            } else {
                self.captionLabel.text = @"动画已收藏, 但您未允许番剧助手进行推送";
            }
        } else {
            self.captionLabel.text = @"动画尚未收藏, 相关更新信息不会推送到您的设备";
        }
    }
}

- (void)p_addSubviews {
    UIView *superView = self.view;
    UIUserInterfaceIdiom deviceType = [[UIDevice currentDevice] userInterfaceIdiom];
    
    self.largeImageView = [[UIImageView alloc] init];
    self.largeImageView.layer.cornerRadius = 10;
    self.largeImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.largeImageView.clipsToBounds = YES;
    [superView addSubview:self.largeImageView];
    
    self.favoriteButton = [[RoundRectSwitcher alloc] init];
    CGFloat titleSize = (deviceType == UIUserInterfaceIdiomPad)
    ? [[UIFont preferredFontForTextStyle:UIFontTextStyleTitle2] pointSize]
    : [[UIFont preferredFontForTextStyle:UIFontTextStyleTitle3] pointSize];
    self.favoriteButton.titleLabel.font = [UIFont systemFontOfSize:titleSize];
    self.favoriteButton.titleOn = @"弃番";
    self.favoriteButton.titleOff = @"追番";
    [superView addSubview:self.favoriteButton];
    
    self.captionLabel = [[UILabel alloc] init];
    self.captionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.captionLabel.numberOfLines = 0;
    [self.captionLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [superView addSubview:self.captionLabel];
    
    if (deviceType == UIUserInterfaceIdiomPad) {
        self.showDetailButton = [[RoundRectSwitcher alloc] init];
        self.showDetailButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        self.showDetailButton.imageOn = [UIImage imageNamed:@"show_detail_on"];
        self.showDetailButton.imageOff = [UIImage imageNamed:@"show_detail_off"];
        self.showDetailButton.status = YES;
        [superView addSubview:self.showDetailButton];
    }
    
    self.titleLabel = [[UILabel alloc] init];
    UIFont *titleLabelFont = (deviceType == UIUserInterfaceIdiomPad)
    ? [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1]
    : [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    self.titleLabel.font = titleLabelFont;
    self.titleLabel.numberOfLines = 0;
    [self.titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [superView addSubview:self.titleLabel];
    
    self.detailView = [[UIScrollView alloc] init];
    self.detailView.bounces = NO;
    [superView addSubview:self.detailView];
    
    self.stuffLabel = [[UILabel alloc] init];
    self.stuffLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.stuffLabel.textColor = [UIColor darkGrayColor];
    self.stuffLabel.numberOfLines = 0;
    [self.stuffLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [self.detailView addSubview:self.stuffLabel];
    
    self.cvLabel = [[UILabel alloc] init];
    self.cvLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.cvLabel.textColor = [UIColor darkGrayColor];
    self.cvLabel.numberOfLines = 0;
    [self.cvLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [self.detailView addSubview:self.cvLabel];
    
    self.synopsisLabel = [[UILabel alloc] init];
    UIFont *synopsisLabelFont = (deviceType == UIUserInterfaceIdiomPad)
    ? [UIFont preferredFontForTextStyle:UIFontTextStyleBody]
    : [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.synopsisLabel.font = synopsisLabelFont;
    self.synopsisLabel.numberOfLines = 0;
    [self.synopsisLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [self.detailView addSubview:self.synopsisLabel];
    
    self.separationLine = [[UIView alloc] init];
    self.separationLine.backgroundColor = [UIColor lightGrayColor];
    [superView addSubview:self.separationLine];
    
    self.showEpisodeTitleButton = [[RoundRectSwitcher alloc] init];
    self.showEpisodeTitleButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.showEpisodeTitleButton.imageOn = [UIImage imageNamed:@"show_episode_title_loading"];
    self.showEpisodeTitleButton.imageOff = [UIImage imageNamed:@"show_episode_title_off"];;
    self.showEpisodeTitleButton.status = NO;
    [superView addSubview:self.showEpisodeTitleButton];
    
    self.progressLabel = [[UILabel alloc] init];
    self.progressLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.stuffLabel.textColor = [UIColor darkGrayColor];
    self.progressLabel.numberOfLines = 0;
    [self.progressLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [superView addSubview:self.progressLabel];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    UIButton *testButton = [UIButton buttonWithType:UIButtonTypeSystem];
    layout.estimatedItemSize = CGSizeMake(LCMinEpisodeButtonWidth, testButton.intrinsicContentSize.height);
    layout.minimumInteritemSpacing = LCPadding;
    layout.minimumLineSpacing = LCPadding;
    self.episodeButtonsView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.episodeButtonsView.backgroundColor = [UIColor whiteColor];
    self.episodeButtonsView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.episodeButtonsView.delegate = self;
    self.episodeButtonsView.dataSource = self;
    [self.episodeButtonsView registerClass:[EpisodeButtonCell class] forCellWithReuseIdentifier:kReuseIdentifier];
    [superView addSubview:self.episodeButtonsView];
}

- (void)p_addConstraints {
    UIView *superView = self.view;
    UIUserInterfaceIdiom deviceType = [[UIDevice currentDevice] userInterfaceIdiom];
    CGFloat padding = LCPadding;
    CGFloat paddingLarge = (deviceType == UIUserInterfaceIdiomPad) ? LCPaddingLarge : LCPadding;
    
    [self.largeImageView makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_topLayoutGuide).with.offset(paddingLarge);
        make.right.equalTo(@(-paddingLarge));
        make.width.equalTo(superView).multipliedBy(LCLargeImageSpaceOccupiyRatio);
        make.height.equalTo(self.largeImageView.width).multipliedBy(LCLargeImageAspectRatio);
    }];
    
    [self.favoriteButton makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.largeImageView.bottom).with.offset(paddingLarge);
        make.left.equalTo(self.largeImageView);
        make.right.equalTo(self.largeImageView);
    }];
    [self.favoriteButton setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                         forAxis:UILayoutConstraintAxisHorizontal];
    [self.favoriteButton setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                         forAxis:UILayoutConstraintAxisVertical];
    
    [self.captionLabel makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.favoriteButton.bottom).with.offset(padding);
        make.left.equalTo(self.largeImageView);
        make.right.equalTo(self.largeImageView);
    }];
    
    if (deviceType == UIUserInterfaceIdiomPad) {
        [self.showDetailButton makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.titleLabel);
            make.right.equalTo(self.largeImageView.left).with.offset(-paddingLarge * 2);
            make.width.equalTo(self.showDetailButton.height);
            make.height.equalTo(self.showEpisodeTitleButton);
        }];
        [self.showDetailButton setContentHuggingPriority:UILayoutPriorityRequired
                                                 forAxis:UILayoutConstraintAxisHorizontal];
    }
    
    [self.titleLabel makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_topLayoutGuide).with.offset(paddingLarge);
        make.left.equalTo(@(paddingLarge));
        if (deviceType == UIUserInterfaceIdiomPad) {
            make.right.equalTo(self.showDetailButton.left).with.offset(-paddingLarge);
        } else {
            make.right.equalTo(self.largeImageView.left).with.offset(-paddingLarge * 2);
        }
    }];
    
    CGFloat detailOccupiyRatio = (deviceType == UIUserInterfaceIdiomPad)
    ? LCDetailSpaceOccupiyRatio
    : LCDetailSpaceOccupiyRatioPhone;
    [self.detailView makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.bottom).with.offset(paddingLarge);
        make.left.equalTo(@(paddingLarge));
        make.right.equalTo(self.largeImageView.left).with.offset(-paddingLarge * 2);
        make.height.equalTo(superView).multipliedBy(detailOccupiyRatio);
    }];
    
    [self.stuffLabel makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@0);
        make.left.equalTo(superView).with.offset(paddingLarge);
        make.right.equalTo(self.largeImageView.left).with.offset(-paddingLarge * 2);
    }];
    
    [self.cvLabel makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.stuffLabel.bottom).with.offset(padding);
        make.left.equalTo(superView).with.offset(paddingLarge);
        make.right.equalTo(self.largeImageView.left).with.offset(-paddingLarge * 2);
    }];
    
    [self.synopsisLabel makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cvLabel.bottom).with.offset(paddingLarge);
        make.left.equalTo(superView).with.offset(paddingLarge);
        make.right.equalTo(self.largeImageView.left).with.offset(-paddingLarge * 2);
        make.bottom.equalTo(@0);
    }];
    
    [self.separationLine makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.detailView.bottom).with.offset(padding);
        make.height.equalTo(@1);
        make.left.equalTo(@(paddingLarge));
        if (deviceType == UIUserInterfaceIdiomPad) {
            make.right.equalTo(self.largeImageView.left).with.offset(-paddingLarge * 2);
        } else {
            make.right.equalTo(@(-paddingLarge));
        }
    }];
    
    [self.showEpisodeTitleButton makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.separationLine.bottom).with.offset(padding);
        make.right.equalTo(self.separationLine);
        make.width.equalTo(self.showEpisodeTitleButton.height);
        make.height.equalTo(self.progressLabel).multipliedBy(1.5);
    }];
    
    [self.progressLabel makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.showEpisodeTitleButton);
        make.left.equalTo(@(paddingLarge));
        make.right.equalTo(self.showEpisodeTitleButton.left).with.offset(-paddingLarge);
    }];
    
    [self.progressLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    
    [self.episodeButtonsView makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.showEpisodeTitleButton.bottom).with.offset(padding);
        make.left.equalTo(@(paddingLarge));
        make.right.equalTo(self.separationLine);
        make.bottom.equalTo(@(-padding));
    }];
    
    [super updateViewConstraints];
}


@end
