//
//  MainViewController.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/29.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "MainViewController.h"

#import "SearchViewController.h"
#import "DailyDeliveryViewController.h"
#import "MyFavoriteViewController.h"
#import "BangumiDetailViewController.h"
#import "IndicatorBarButton.h"
#import "CustomBadgeView.h"
#import "LayoutConstant.h"

#import "AGRequest.h"
#import "NetworkConstant.h"
#import "Bangumi+Create.h"
#import "Schedule+Create.h"
#import "NotificationManager.h"
#import "UIColor+ExtraColor.h"

#define MAS_SHORTHAND
#import "Masonry.h"

NSString * const AGShowDetailSegueIdentifier = @"Show Detail";

@interface MainViewController ()

@property (nonatomic, strong) SearchViewController *searchVC;
@property (nonatomic, strong) DailyDeliveryViewController *dailyDeliveryVC;
@property (nonatomic, strong) MyFavoriteViewController *myFavoriteVC;
@property (nonatomic, strong) UIViewController *currentVC;

@property (nonatomic, strong) UIBarButtonItem *searchButton;
@property (nonatomic, strong) UIBarButtonItem *dailyDeliveryButton;
@property (nonatomic, strong) UIBarButtonItem *myFavoriteButton;
@property (nonatomic, strong) UIBarButtonItem *badge;

@end

@implementation MainViewController

#pragma mark - UIViewController (super class)

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self p_setupNavigationBar];
    
    self.searchVC = [[SearchViewController alloc] init];
    self.dailyDeliveryVC = [[DailyDeliveryViewController alloc] init];
    self.myFavoriteVC = [[MyFavoriteViewController alloc] init];
    self.currentVC = self.dailyDeliveryVC;
    [self p_displayContentController:self.currentVC];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NotificationManager *manager = [NotificationManager sharedNotificationManager];
    if (manager.jumpStatus == AGJumpByNotaficationStatusHandling) {
        manager.jumpStatus = AGJumpByNotaficationStatusCompleted;
        [self doJumpToEpisode];
    }
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.currentVC;
}

#pragma mark - FetcherViewController (super class)

- (NSFetchRequest *)fetchRequest {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Bangumi"];
    request.predicate = [NSPredicate predicateWithFormat:@"isFavorite == TRUE"];
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
    AGRequest *request = [[AGRequest alloc] init];
    [[request fetchMyFavorite] subscribeCompleted:^{ }];
}

- (void)updateUI {
    NSArray *matches = [self.fetchedResultsController fetchedObjects];
    NSInteger count = 0;
    for (Bangumi *bangumi in matches) {
        if (bangumi.lastReleasedEpisode.integerValue > bangumi.lastWatchedEpisode.integerValue) ++count;
    }
    CustomBadgeView *badge = (CustomBadgeView *)self.badge.customView;
    badge.favorite = (count > 0);
    badge.eventCount = count;
    [UIApplication sharedApplication].applicationIconBadgeNumber = count;
}

- (void)doJumpToEpisode {
    NotificationManager *manager = [NotificationManager sharedNotificationManager];
    NSNumber *bangumiIdentifier = manager.jumpDestinationBangumiIdentifier;
    [self performSegueWithIdentifier:AGShowDetailSegueIdentifier sender:bangumiIdentifier];
}

#pragma mark - Private Methods

- (void)p_setupNavigationBar {
    self.navigationController.navigationBar.barTintColor = [UIColor darkGrayColor];
    self.navigationController.navigationBar.titleTextAttributes = @{ NSForegroundColorAttributeName: [UIColor whiteColor] };
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    self.searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                                      target:self
                                                                      action:@selector(p_touchSearchButton)];
    
    IndicatorBarButton *dailyDeliveryIB = [[IndicatorBarButton alloc] initWithTitle:@"每日放送"
                                                                              color:self.view.tintColor];
    dailyDeliveryIB.indicator = YES;
    [[dailyDeliveryIB.touchSignal
      deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(id  _Nullable x) {
         [self p_touchDailyDeliveryButton];
     }];
    self.dailyDeliveryButton = [[UIBarButtonItem alloc] initWithCustomView:dailyDeliveryIB];
    
    IndicatorBarButton *myFavoriteIB = [[IndicatorBarButton alloc] initWithTitle:@"我的收藏"
                                                                           color:self.view.tintColor];
    myFavoriteIB.indicator = NO;
    [[myFavoriteIB.touchSignal
      deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(id  _Nullable x) {
         [self p_touchMyFavoriteButton];
     }];
    self.myFavoriteButton = [[UIBarButtonItem alloc] initWithCustomView:myFavoriteIB];
    
    UIUserInterfaceIdiom deviceType = [[UIDevice currentDevice] userInterfaceIdiom];
    CGFloat badgeWidth = (deviceType == UIUserInterfaceIdiomPad) ? LCMaxCustomBadgeWidth : LCMaxCustomBadgeWidthPhone;
    CGFloat badgeHeight = (deviceType == UIUserInterfaceIdiomPad) ? LCCustomBadgeHeight : LCCustomBadgeHeightPhone;
    CGRect badgeFrame = CGRectMake(0, 0, badgeWidth, badgeHeight);
    CustomBadgeView *badge = [[CustomBadgeView alloc] initWithFrame:badgeFrame];
    badge.userInteractionEnabled = YES;
    UITapGestureRecognizer *badgeGestureRecognizer = [[UITapGestureRecognizer alloc] init];
    
    [[badgeGestureRecognizer.rac_gestureSignal
      deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(__kindof UIGestureRecognizer * _Nullable x) {
         [self p_touchBadgeView];
     }];
    
    [badge addGestureRecognizer:badgeGestureRecognizer];
    self.badge = [[UIBarButtonItem alloc] initWithCustomView:badge];
    
    self.navigationItem.title = (deviceType == UIUserInterfaceIdiomPad) ? @"番剧助手" : @"";
    self.navigationItem.leftBarButtonItems = @[ self.searchButton,
                                                self.dailyDeliveryButton, self.myFavoriteButton,
                                                self.badge ];
}

- (void)p_touchSearchButton {
    if (self.currentVC == self.searchVC) return;
    self.searchButton.tintColor = [UIColor ag_pinkColor];
    ((IndicatorBarButton *)self.dailyDeliveryButton.customView).indicator = NO;
    ((IndicatorBarButton *)self.myFavoriteButton.customView).indicator = NO;
    [self p_replaceViewController:self.currentVC withViewController:self.searchVC];
}

- (void)p_touchDailyDeliveryButton {
    if (self.currentVC == self.dailyDeliveryVC) return;
    self.searchButton.tintColor = self.navigationController.navigationBar.tintColor;
    ((IndicatorBarButton *)self.dailyDeliveryButton.customView).indicator = YES;
    ((IndicatorBarButton *)self.myFavoriteButton.customView).indicator = NO;
    [self p_replaceViewController:self.currentVC withViewController:self.dailyDeliveryVC];
}

- (void)p_touchMyFavoriteButton {
    if (self.currentVC == self.myFavoriteVC) return;
    self.searchButton.tintColor = self.navigationController.navigationBar.tintColor;
    ((IndicatorBarButton *)self.myFavoriteButton.customView).indicator = YES;
    ((IndicatorBarButton *)self.dailyDeliveryButton.customView).indicator = NO;
    [self p_replaceViewController:self.currentVC withViewController:self.myFavoriteVC];
}

- (void)p_touchBadgeView {
    CustomBadgeView *badge = (CustomBadgeView *)self.badge.customView;
    if (!badge.favorite) return;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"全部标记为已看"
                                                                   message:@"确定要将所有未看剧集标记为已看吗?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"是" style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
                                                          [self p_markAllEpisodesWatched];
                                                      }];
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"否" style:UIAlertActionStyleCancel
                                                     handler:^(UIAlertAction * action) { }];
    
    
    [alert addAction:yesAction];
    [alert addAction:noAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)p_markAllEpisodesWatched {
    AGRequest *request = [[AGRequest alloc] init];
    [[request markAllEpisodesWatched] subscribeCompleted:^{ }];
}

- (void)p_displayContentController:(UIViewController *)content {
    [self addChildViewController:content];
    content.view.frame = self.view.bounds;
    [self.view addSubview:content.view];
    [content didMoveToParentViewController:self];
}

- (void)p_hideContentController:(UIViewController *)content {
    [content willMoveToParentViewController:nil];
    [content.view removeFromSuperview];
    [content removeFromParentViewController];
}

- (void)p_replaceViewController:(UIViewController *)oldVC withViewController:(UIViewController *)newVC {
    [self p_hideContentController:oldVC];
    [self p_displayContentController:newVC];
    self.currentVC = newVC;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:AGShowDetailSegueIdentifier]) {
        if ([segue.destinationViewController isKindOfClass:[BangumiDetailViewController class]]
            && [sender isKindOfClass:[NSNumber class]]) {
            BangumiDetailViewController *detailVC = (BangumiDetailViewController *) segue.destinationViewController;
            NSNumber *bangumiIdentifier = (NSNumber *)sender;
            detailVC.bangumiIdentifier = bangumiIdentifier;
        }
    }
}

- (IBAction)jumpUnwindAction:(UIStoryboardSegue*)unwindSegue { }

@end
