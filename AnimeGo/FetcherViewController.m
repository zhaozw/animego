//
//  FetcherViewController.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/5.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "FetcherViewController.h"

#import "AppDelegate.h"
#import "NetworkConstant.h"
#import "Bangumi+Create.h"
#import "Schedule+Create.h"
#import "NSDate+Format.h"
#import "NotificationManager.h"
#import "NetworkWorker.h"

@interface FetcherViewController ()

@property (nonatomic, weak) NSManagedObjectContext *privateMOC;
@property (nonatomic, strong) NSTimer *autoRefreshTimer;

@end

@implementation FetcherViewController

#pragma mark - UIViewController (super class)

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup ManagedObjectContext
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.mainMOC = appDelegate.mainMOC;
    self.privateMOC = appDelegate.privateMOC;
    
    // Setup FetchedResultsController
    NSFetchRequest *request = [self fetchRequest];
    if (request) {
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:[self fetchRequest]
                                                                            managedObjectContext:self.mainMOC
                                                                              sectionNameKeyPath:nil
                                                                                       cacheName:nil];
        self.fetchedResultsController.delegate = self;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Fetch and display data
    if (self.fetchedResultsController) [self.fetchedResultsController performFetch:nil];
    [self fetchRemoteData];
    
    // Setup refresh button
    if ([self hasRefreshButton]) {
        UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                       target:self
                                                                                       action:@selector(touchRefreshButton)];
        self.navigationItem.rightBarButtonItem = refreshButton;
    }
    
    // Setup autorefresh timer
    NSInteger autoRefreshTimeInterval = [self autoRefreshTimeInterval];
    if (autoRefreshTimeInterval > 0) {
        self.autoRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:autoRefreshTimeInterval
                                                                 target:self
                                                               selector:@selector(p_autoRefreshAction:)
                                                               userInfo:nil
                                                                repeats:YES];
    }
    
    // Add observer
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentNeedUpdateNofification)
                                                 name:AGContentNeedUpdateNofification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentNeedReOrderNofification)
                                                 name:AGContentNeedReOrderNofification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(p_jumpToEpisodeHandler)
                                                 name:AGJumpToPageNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    // Jump
    [self p_jumpToEpisodeHandler];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.navigationItem.rightBarButtonItem = nil;
    if (self.autoRefreshTimer) [self.autoRefreshTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - <NSFetchedResultsControllerDelegate>

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self updateUI];
}

#pragma mark - Private Methods

- (void)p_autoRefreshAction:(NSTimer *)timer {
    [self fetchRemoteData];
}

- (void)p_jumpToEpisodeHandler {
    NotificationManager *manager = [NotificationManager sharedNotificationManager];
    if (manager.jumpStatus != AGJumpByNotaficationStatusUntreated) return;
    manager.jumpStatus = AGJumpByNotaficationStatusHandling;
    [self jumpToPage];
}

#pragma mark - Protected Methods

- (void)didBecomeActive {
    [self fetchRemoteData];
    [self updateUI];
    [self p_jumpToEpisodeHandler];
}

- (void)willResignActive {

}

- (void)contentNeedUpdateNofification {
    [self fetchRemoteData];
    [self updateUI];
}

- (void)contentNeedReOrderNofification {

}

- (void)jumpToPage {
    
}

- (void)alertConnectionError {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"网络连接失败"
                                                                   message:@"番剧助手目前无法获取最新的番剧信息和用户数据"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"我知道了" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) { }];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSFetchRequest *)fetchRequest {
    return nil;
}

- (NSTimeInterval)autoRefreshTimeInterval {
    return 0;
}

- (BOOL)hasRefreshButton {
    return YES;
}

- (void)touchRefreshButton {
    [self fetchRemoteData];
}

- (void)fetchRemoteData { }

- (void)updateUI { }

@end
