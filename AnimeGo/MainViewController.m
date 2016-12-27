//
//  MainViewController.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/29.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "MainViewController.h"
#import "DailyDeliveryViewController.h"
#import "MyFavoriteViewController.h"
#import "BangumiDetailViewController.h"
#import "Bangumi+Create.h"
#import "Schedule+Create.h"
#import "IndicatorBarButton.h"
#import "CustomBadge.h"
#import "LayoutConstant.h"
#import "NotificationManager.h"
#import "LayoutConstant.h"
#import "NetworkConstant.h"

#define MAS_SHORTHAND
#import "Masonry.h"

NSString * const kSegueIdentifier = @"Show Detail";

@interface MainViewController ()

@property (strong, nonatomic) DailyDeliveryViewController *dailyDeliveryVC;
@property (strong, nonatomic) MyFavoriteViewController *myFavoriteVC;
@property (strong, nonatomic) UIViewController *currentVC;
@property (nonatomic) BOOL isJumpToEpisodeHandling;

@property (strong, nonatomic) UIBarButtonItem *dailyDeliveryButton;
@property (strong, nonatomic) UIBarButtonItem *myFavoriteButton;
@property (strong, nonatomic) UIBarButtonItem *badge;

@end

@implementation MainViewController

#pragma mark - Private Properties

- (DailyDeliveryViewController *)dailyDeliveryVC {
    if (!_dailyDeliveryVC) {
        _dailyDeliveryVC = [[DailyDeliveryViewController alloc] init];
    }
    return _dailyDeliveryVC;
}

- (MyFavoriteViewController *)myFavoriteVC {
    if (!_myFavoriteVC) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.itemSize = CGSizeMake(100, 100);
        _myFavoriteVC = [[MyFavoriteViewController alloc] init];
    }
    return _myFavoriteVC;
}

#pragma mark - Life Cycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.barTintColor = [UIColor darkGrayColor];
    self.navigationController.navigationBar.titleTextAttributes = @{ NSForegroundColorAttributeName: [UIColor whiteColor] };
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    self.isJumpToEpisodeHandling = NO;
    [self dailyDeliveryVC];
    [self myFavoriteVC];
    
    IndicatorBarButton *dailyDeliveryIB = [[IndicatorBarButton alloc] initWithTitle:@"每日放送"
                                                                     indicatorColor:self.view.tintColor
                                                                             target:self
                                                                             action:@selector(touchDailyDeliveryButton)];
    IndicatorBarButton *myFavoriteIB = [[IndicatorBarButton alloc] initWithTitle:@"我的收藏"
                                                                  indicatorColor:self.view.tintColor
                                                                     target:self
                                                                     action:@selector(touchMyFavoriteButton)];
    dailyDeliveryIB.indicator = YES;
    myFavoriteIB.indicator = NO;
    
    self.dailyDeliveryButton = [[UIBarButtonItem alloc] initWithCustomView:dailyDeliveryIB];
    self.myFavoriteButton = [[UIBarButtonItem alloc] initWithCustomView:myFavoriteIB];
    
    UIUserInterfaceIdiom deviceType = [[UIDevice currentDevice] userInterfaceIdiom];
    CGFloat badgeWidth = (deviceType == UIUserInterfaceIdiomPad) ? LCMaxCustomBadgeWidth : LCMaxCustomBadgeWidthPhone;
    CGFloat badgeHeight = (deviceType == UIUserInterfaceIdiomPad) ? LCCustomBadgeHeight : LCCustomBadgeHeightPhone;
    CGRect badgeFrame = CGRectMake(0, 0, badgeWidth, badgeHeight);
    CustomBadge *badge = [[CustomBadge alloc] initWithFrame:badgeFrame];
    badge.userInteractionEnabled = YES;
    UITapGestureRecognizer *badgeGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self
                                                                                            action:@selector(touchBadge)];
    [badge addGestureRecognizer:badgeGestureRecognizer];
    self.badge = [[UIBarButtonItem alloc] initWithCustomView:badge];
    
    self.navigationItem.title = @"番剧助手";
    self.navigationItem.leftBarButtonItems = @[self.dailyDeliveryButton, self.myFavoriteButton, self.badge];
    
    self.currentVC = self.dailyDeliveryVC;
    [self displayContentController:self.currentVC];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.isJumpToEpisodeHandling) {
        self.isJumpToEpisodeHandling = NO;
        [self doJumpToEpisode];
    }
}

#pragma mark - Protected Methods

- (NSFetchRequest *)fetchRequest {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Bangumi"];
    request.predicate = [NSPredicate predicateWithFormat:@"isfavorite == TRUE"];
    NSSortDescriptor *identifierSort = [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO];
    [request setSortDescriptors:@[identifierSort]];
    return request;
}

- (NSTimeInterval)autoRefreshTimeInterval {
    return 0;
}

- (BOOL)hasRefreshButton {
    return NO;
}

- (void)fetchRemoteData {
    [self fetchMyFavoriteSuccess:nil
                 connectionError:nil
                     serverError:nil];
}

- (void)updateUI {
    NSArray *matches = [self.fetchedResultsController fetchedObjects];
    NSInteger count = 0;
    for (Bangumi *bangumi in matches) {
        if (bangumi.lastreleasedepisode.integerValue > bangumi.lastwatchedepisode.integerValue) ++count;
    }
    CustomBadge *badge = (CustomBadge *)self.badge.customView;
    badge.isFavorite = (count > 0);
    badge.eventCount = count;
    [UIApplication sharedApplication].applicationIconBadgeNumber = count;
}

#pragma mark - Private Methods

- (void)touchDailyDeliveryButton {
    if (self.currentVC == self.dailyDeliveryVC) return;
    ((IndicatorBarButton *)self.dailyDeliveryButton.customView).indicator = YES;
    ((IndicatorBarButton *)self.myFavoriteButton.customView).indicator = NO;
    [self replaceViewController:self.currentVC withViewController:self.dailyDeliveryVC];
}

- (void)touchMyFavoriteButton {
    if (self.currentVC == self.myFavoriteVC) return;
    ((IndicatorBarButton *)self.myFavoriteButton.customView).indicator = YES;
    ((IndicatorBarButton *)self.dailyDeliveryButton.customView).indicator = NO;
    [self replaceViewController:self.currentVC withViewController:self.myFavoriteVC];
}

- (void)touchBadge {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"全部标记为已看"
                                                                   message:@"确定要将所有未看剧集标记为已看吗?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"是" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [self markAllEpisodesWatched];
                                                          }];
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"否" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) { }];


    [alert addAction:yesAction];
    [alert addAction:noAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.currentVC;
}

- (void)markAllEpisodesWatched {
    [self markAllEpisodesWatchedSuccess:nil
                        connectionError:nil
                            serverError:nil];
}

- (void)displayContentController:(UIViewController*)content {
    [self addChildViewController:content];
    content.view.frame = self.view.bounds;
    [self.view addSubview:content.view];
    [content didMoveToParentViewController:self];
}

- (void)hideContentController:(UIViewController*)content {
    [content willMoveToParentViewController:nil];
    [content.view removeFromSuperview];
    [content removeFromParentViewController];
}


- (void)replaceViewController:(UIViewController *)oldVC withViewController:(UIViewController *)newVC {
    [self hideContentController:oldVC];
    [self displayContentController:newVC];
    self.currentVC = newVC;
}

- (void)doJumpToEpisode {
    NotificationManager *manager = [NotificationManager sharedNotificationManager];
    NSNumber *bangumiIdentifier = manager.jumpToEpisodeNotificationDestinationBangumiIdentifier;
    [self performSegueWithIdentifier:kSegueIdentifier sender:bangumiIdentifier];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kSegueIdentifier]) {
        if ([segue.destinationViewController isKindOfClass:[BangumiDetailViewController class]]
            && [sender isKindOfClass:[NSNumber class]]) {
            BangumiDetailViewController *detailVC = (BangumiDetailViewController *) segue.destinationViewController;
            NSNumber *bangumiIdentifier = (NSNumber *)sender;
            detailVC.bangumiIdentifier = bangumiIdentifier;
        }
    }
}

- (IBAction)jumpUnwindAction:(UIStoryboardSegue*)unwindSegue {
    self.isJumpToEpisodeHandling = YES;
}

@end
