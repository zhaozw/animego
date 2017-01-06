//
//  BangumiDetailViewController.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/26.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "BangumiDetailViewController.h"
#import "EpisodeDetailViewController.h"
#import "NotificationManager.h"
#import "NetworkWorker.h"
#import "NetworkConstant.h"
#import "LayoutConstant.h"
#import "NotificationManager.h"
#import "EpisodeButtonCell.h"
#import "NSDate+Convert.h"
#import "Schedule+Create.h"

#define MAS_SHORTHAND
#import "Masonry.h"

static NSString * const kReuseIdentifier = @"Cell";

@interface BangumiDetailViewController ()

@property (strong, nonatomic) Bangumi *bangumi;

@property (strong, nonatomic) RoundRectSwitcher *showDetailButton;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UIScrollView *detailView;
@property (strong, nonatomic) UILabel *stuffLabel;
@property (strong, nonatomic) UILabel *cvLabel;
@property (strong, nonatomic) UILabel *synopsisLabel;
@property (strong, nonatomic) UIView *separationLine;
@property (strong, nonatomic) RoundRectSwitcher *showEpisodeTitleButton;
@property (strong, nonatomic) UILabel *progressLabel;
@property (strong, nonatomic) UICollectionView *episodeButtonsView;

@property (strong, nonatomic) UIImageView *largeImageView;
@property (strong, nonatomic) UILabel *captionLabel;
@property (strong, nonatomic) RoundRectSwitcher *favoriteButton;

@property (strong, nonatomic) NSMutableDictionary *episodeDict;

@end

@implementation BangumiDetailViewController

#pragma mark Lifecycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *superView = self.view;
    UIUserInterfaceIdiom deviceType = [[UIDevice currentDevice] userInterfaceIdiom];
    CGFloat padding = LCPadding;
    CGFloat paddingLarge = (deviceType == UIUserInterfaceIdiomPad) ? LCPaddingLarge : LCPadding;
    
    self.largeImageView = [[UIImageView alloc] init];
    self.largeImageView.layer.cornerRadius = 10;
    self.largeImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.largeImageView.clipsToBounds = YES;
    [superView addSubview:self.largeImageView];
    
    self.favoriteButton = [[RoundRectSwitcher alloc] init];
    CGFloat titleSize = [[UIFont preferredFontForTextStyle:UIFontTextStyleTitle2] pointSize];
    self.favoriteButton.titleLabel.font = [UIFont systemFontOfSize:titleSize];
    self.favoriteButton.titleOn = @"弃番";
    self.favoriteButton.titleOff = @"追番";
    self.favoriteButton.delegate = self;
    [superView addSubview:self.favoriteButton];
    
    if (deviceType == UIUserInterfaceIdiomPad) {
        self.captionLabel = [[UILabel alloc] init];
        self.captionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        self.captionLabel.numberOfLines = 0;
        [self.captionLabel setLineBreakMode:NSLineBreakByWordWrapping];
        [superView addSubview:self.captionLabel];
    }
    
    self.showDetailButton = [[RoundRectSwitcher alloc] init];
    self.showDetailButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.showDetailButton.titleOn = @"隐藏番剧信息";
    self.showDetailButton.titleOff = @"显示番剧信息";
    self.showDetailButton.status = YES;
    self.showDetailButton.delegate = self;
    [superView addSubview:self.showDetailButton];

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
    self.showEpisodeTitleButton.titleOn = @"加载中";
    self.showEpisodeTitleButton.titleOff = @"显示每集标题";
    self.showEpisodeTitleButton.status = NO;
    self.showEpisodeTitleButton.delegate = self;
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
    layout.minimumLineSpacing = padding;
    layout.minimumInteritemSpacing = padding;
    self.episodeButtonsView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.episodeButtonsView.backgroundColor = [UIColor whiteColor];
    self.episodeButtonsView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.episodeButtonsView.delegate = self;
    self.episodeButtonsView.dataSource = self;
    [self.episodeButtonsView registerClass:[EpisodeButtonCell class] forCellWithReuseIdentifier:kReuseIdentifier];
    [superView addSubview:self.episodeButtonsView];
    
    [self.largeImageView makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_topLayoutGuide).with.offset(paddingLarge);
        make.right.equalTo(@(-paddingLarge));
        make.width.equalTo(superView).multipliedBy(LCLargeImageSpaceOccupiyRatio);
        if (deviceType == UIUserInterfaceIdiomPad) {
            make.height.equalTo(self.largeImageView.width).multipliedBy(LCLargeImageAspectRatio);
        }
    }];
    
    [self.favoriteButton makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.largeImageView.bottom).with.offset(paddingLarge);
        make.left.equalTo(self.largeImageView);
        make.right.equalTo(self.largeImageView);
        if (deviceType != UIUserInterfaceIdiomPad) {
            make.bottom.equalTo(self.mas_bottomLayoutGuide).with.offset(-paddingLarge);
        }
    }];
    [self.favoriteButton setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                         forAxis:UILayoutConstraintAxisHorizontal];
    [self.favoriteButton setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                         forAxis:UILayoutConstraintAxisVertical];
    
    if (deviceType == UIUserInterfaceIdiomPad) {
        [self.captionLabel makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.favoriteButton.bottom).with.offset(padding);
            make.left.equalTo(self.largeImageView);
            make.right.equalTo(self.largeImageView);
        }];
    }
    
    [self.showDetailButton makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.titleLabel);
        make.right.equalTo(self.largeImageView.left).with.offset(-paddingLarge * 2);
    }];
    [self.showDetailButton setContentHuggingPriority:UILayoutPriorityRequired
                                             forAxis:UILayoutConstraintAxisHorizontal];
    
    [self.titleLabel makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_topLayoutGuide).with.offset(paddingLarge);
        make.left.equalTo(@(paddingLarge));
        make.right.equalTo(self.showDetailButton.left).with.offset(-paddingLarge);
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
        make.left.equalTo(@(paddingLarge));
        make.right.equalTo(self.largeImageView.left).with.offset(-paddingLarge * 2);
        make.height.equalTo(@1);
    }];
    
    [self.showEpisodeTitleButton makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.separationLine.bottom).with.offset(padding);
        make.right.equalTo(self.largeImageView.left).with.offset(-paddingLarge * 2);
    }];
    [self.showEpisodeTitleButton setContentHuggingPriority:UILayoutPriorityRequired
                                             forAxis:UILayoutConstraintAxisHorizontal];
    
    [self.progressLabel makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.showEpisodeTitleButton);
        make.left.equalTo(@(paddingLarge));
        make.right.equalTo(self.showEpisodeTitleButton.left).with.offset(-paddingLarge);
    }];
    
    [self.episodeButtonsView makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.showEpisodeTitleButton.bottom).with.offset(padding);
        make.left.equalTo(@(paddingLarge));
        make.right.equalTo(self.largeImageView.left).with.offset(-paddingLarge * 2);
        make.bottom.equalTo(@(-padding));
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSSet *episodesSet = self.bangumi.schedule;
    for (Schedule *schedule in episodesSet) {
        [self.episodeDict setObject:schedule.title forKey:@(schedule.episodeNumber.integerValue)];
    }
    [self updateUI];
    [self fetchListAllEpisodesWithBangumiId:self.bangumi.identifier
                                    success:^(NSArray *data) {
                                        for (NSDictionary *scheduleDict in data) {
                                            NSNumber *episodeNumber = [scheduleDict valueForKey:AGScheduleKeyEpisodeNumber];
                                            NSString *title = [scheduleDict valueForKey:AGScheduleKeyTitle];
                                            [self.episodeDict setObject:title forKey:@(episodeNumber.integerValue)];
                                        }
                                        self.showEpisodeTitleButton.titleOn = @"隐藏每集标题";
                                        [self.episodeButtonsView reloadData];
                                    }
                            connectionError:nil
                                serverError:nil];
}

- (void)doJumpToEpisode {
    [self performSegueWithIdentifier:@"Back" sender:self];
}

#pragma mark <RoundRectSwitcherDelegate>

- (void)switcherView:(RoundRectSwitcher *)switcherView statusChanged:(BOOL)status {
    if (switcherView == self.showDetailButton) {
        [self touchShowDetailButton];
    } else if (switcherView == self.showEpisodeTitleButton) {
        [self touchShowEpisodeTitleButton];
    } else if (switcherView == self.favoriteButton) {
        [self touchFavoriteButton];
    }
}

#pragma mark <UICollectionViewDataSource>

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
            if (episodeTitle) {
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

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    if ([cell isKindOfClass:[EpisodeButtonCell class]]) {
        EpisodeButtonCell *episodeButtonCell = (EpisodeButtonCell *)cell;
        NSInteger episodeNumber = indexPath.row + self.bangumi.firstReleasedEpisode.integerValue;
        [self fetchEpisodeDetailWithBangumiId:self.bangumi.identifier
                                episodeNumber:@(episodeNumber)
                                      success:nil
                              connectionError:nil
                                  serverError:nil];
        
        EpisodeDetailViewController *episodeDetailVC = [[EpisodeDetailViewController alloc] init];
        episodeDetailVC.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *popoverPC = episodeDetailVC.popoverPresentationController;
        popoverPC.sourceView = episodeButtonCell;
        popoverPC.sourceRect = episodeButtonCell.contentView.bounds;
        popoverPC.delegate = self;
        
        episodeDetailVC.bangumiIdentifier = self.bangumiIdentifier;
        episodeDetailVC.episodeNumber = @(episodeNumber);
        
        [self presentViewController:episodeDetailVC animated:YES completion:nil];
    }
}

#pragma mark - <UIPopoverPresentControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

#pragma mark - Public Property

- (void)fetchRemoteData {
    if (!self.bangumiIdentifier) return;
    [self fetchBangumiDetailWithBangumiId:self.bangumiIdentifier
                                  success:nil
                          connectionError:nil
                              serverError:nil];
}

- (void)updateCaptionLabel {
    if (self.bangumi.status.integerValue == AGBangumiStatusOver) {
        self.captionLabel.text = @"动画已完结";
    } else {
        if ([self.bangumi.isFavorite isEqual:@(YES)]) {
            if ([NotificationManager sharedNotificationManager].enable) {
                self.captionLabel.text = @"动画已收藏, 新的集数一旦更新, 将会立即推送给您";
            } else {
                self.captionLabel.text = @"动画已收藏, 但您未允许番剧助手进行推送, 您可以修改系统设置, 来允许番剧助手向您推送消息";
            }
        } else {
            self.captionLabel.text = @"动画尚未收藏, 相关更新信息不会推送到您的设备";
        }
    }
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
    
    UIUserInterfaceIdiom deviceType = [[UIDevice currentDevice] userInterfaceIdiom];
    if (deviceType == UIUserInterfaceIdiomPad) {
        [[NotificationManager sharedNotificationManager] getNotificationSettingsWithCompletionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateCaptionLabel];
            });
        }];
    }
    
    NSInteger firstReleasedEpisode = (self.bangumi.firstReleasedEpisode).integerValue;
    NSInteger lastReleasedEpisode = (self.bangumi.lastReleasedEpisode).integerValue;
    NSInteger lastWatchedEpisode = (self.bangumi.lastWatchedEpisode).integerValue;
    
    if (self.bangumi.status.integerValue == AGBangumiStatusOver) {
        self.progressLabel.text = [NSString stringWithFormat:@"共%ld集 (已完结)", (long)lastReleasedEpisode];
    } else {
        NSString *releaseWeekdayString = @"";
        NSInteger releaseWeekday = (self.bangumi.releaseWeekday).integerValue;
        if (releaseWeekday > 0 && releaseWeekday < [[NSDate weekdayNameArray] count]) {
            releaseWeekdayString = [NSString stringWithFormat:@"每周更新: %@", [NSDate weekdayNameArray][releaseWeekday]];
        }
        
        NSString *copyrightString = @"";
        for (Schedule *schedule in self.bangumi.schedule) {
            NSString *appURL = [schedule suitableAppURL];
            if (appURL) {
                if ([appURL hasPrefix:@"bilibili://"]) {
                    copyrightString = [NSString stringWithFormat:@", 版权: 哔哩哔哩"];
                } else if ([appURL hasPrefix:@"youku://"]) {
                    copyrightString = [NSString stringWithFormat:@", 版权: 优酷土豆"];
                } else if ([appURL hasPrefix:@"youkuhd://"]) {
                    copyrightString = [NSString stringWithFormat:@", 版权: 优酷土豆"];
                } else if ([appURL hasPrefix:@"iqiyi://"]) {
                    copyrightString = [NSString stringWithFormat:@", 版权: 爱奇艺"];
                } else if ([appURL hasPrefix:@"letvclient://"]) {
                    copyrightString = [NSString stringWithFormat:@", 版权: 乐视"];
                } else if ([appURL hasPrefix:@"ipadletvclient://"]) {
                    copyrightString = [NSString stringWithFormat:@", 版权: 乐视"];
                }
                break;
            }
        }
        
        NSString *lastWatchedString = @"";
        if (lastWatchedEpisode >= firstReleasedEpisode) {
            lastWatchedString = [NSString stringWithFormat:@", 上次看到第%ld集", (long)lastWatchedEpisode];
        }
        NSString *lastReleasedString = [NSString stringWithFormat:@", 已更新至第%ld集", (long)lastReleasedEpisode];
        
        self.progressLabel.text =
            [NSString stringWithFormat:@"%@%@%@%@",
                releaseWeekdayString, copyrightString, lastWatchedString, lastReleasedString];
    }
    
    [[NetworkWorker sharedNetworkWorker] setImageURL:self.bangumi.largeImageURL forImageView:self.largeImageView];
}

- (NSFetchRequest *)fetchRequest {
    if (!self.bangumiIdentifier) return nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Bangumi"];
    request.predicate = [NSPredicate predicateWithFormat:@"identifier == %@", self.bangumiIdentifier];
    NSSortDescriptor *identifierSort = [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO];
    [request setSortDescriptors:@[identifierSort]];
    return request;
}

#pragma mark - Private Methods

- (void)touchShowDetailButton {
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

- (void)touchShowEpisodeTitleButton {
    [self.episodeButtonsView reloadData];
}

- (void)touchFavoriteButton {
    NSNumber *isFavorite = self.favoriteButton.status ? @1 : @0;
    [self updateMyProgressWithBangumiId:self.bangumiIdentifier
                             isFavorite:isFavorite
                     lastWatchedEpisode:self.bangumi.lastWatchedEpisode
                                success:nil
                        connectionError:nil
                            serverError:nil];
}

#pragma mark - Private Properties

- (NSMutableDictionary *)episodeDict {
    if (!_episodeDict) _episodeDict = [[NSMutableDictionary alloc] init];
    return _episodeDict;
}

@end
