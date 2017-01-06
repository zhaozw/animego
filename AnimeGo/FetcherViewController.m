//
//  FetcherViewController.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/5.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "FetcherViewController.h"

#import "AppDelegate.h"
#import "NetworkWorker.h"
#import "NetworkConstant.h"
#import "Bangumi+Create.h"
#import "Schedule+Create.h"
#import "NSDate+Convert.h"
#import "NotificationManager.h"
#import "NetworkWorker.h"

static const NSInteger kDaysOfWeek = 7;
static const NSInteger kPasswordLength = 20;
static const NSInteger kMinTryTimeInterval = 30;
static const NSInteger kMinAlertTimeInerval = 60 * 5;

@interface FetcherViewController ()

@property (strong, readwrite, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (weak, nonatomic) NSManagedObjectContext *privateMOC;
@property (strong, nonatomic) NSTimer *autoRefreshTimer;

@end

@implementation FetcherViewController

#pragma mark - Life Cycle Methods

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
                                                               selector:@selector(autoRefreshAction:)
                                                               userInfo:nil
                                                                repeats:YES];
    }
    
    // Add observer
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentNeedUpdateNofification)
                                                 name:ContentNeedUpdateNofification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(jumpToEpisodeHandler)
                                                 name:JumpToEpisodeNotification
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
    [self jumpToEpisodeHandler];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.navigationItem.rightBarButtonItem = nil;
    if (self.autoRefreshTimer) [self.autoRefreshTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didBecomeActive {
    [self fetchRemoteData];
    [self updateUI];
    [self jumpToEpisodeHandler];
}

- (void)willResignActive {

}

- (void)contentNeedUpdateNofification {
    [self fetchRemoteData];
    [self updateUI];
}

- (void)doJumpToEpisode {
    
}

#pragma mark - Protected Methods

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

- (BOOL)alertNetworkError {
    return NO;
}

#pragma mark - Private Methods

- (void)autoRefreshAction:(NSTimer *)timer {
    [self fetchRemoteData];
}

- (void)alertConnectionError {
    if (![self alertNetworkError]) return;
    
    static NSDate *lastAlert = nil;
    if (lastAlert && [lastAlert timeIntervalSinceNow] > -kMinAlertTimeInerval) return;
    lastAlert = [[NSDate alloc] init];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"网络连接失败"
                                                                   message:@"番剧助手目前无法获取最新的番剧信息和用户数据"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"我知道了" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) { }];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)jumpToEpisodeHandler {
    NotificationManager *manager = [NotificationManager sharedNotificationManager];
    if (manager.isJumpToEpisodeNotificationHandled) return;
    manager.isJumpToEpisodeNotificationHandled = YES;
    [self doJumpToEpisode];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self updateUI];
}

#pragma mark - Network Request

- (void)registerNewUser {
    static NSDate *lastTry = nil;
    if (lastTry && [lastTry timeIntervalSinceNow] > -kMinTryTimeInterval) return;
    lastTry = [[NSDate alloc] init];
    
    NetworkWorker *worker = [NetworkWorker sharedNetworkWorker];
    NSString *password = [self randomString];
    NSDictionary *parameters = @{ @"password": password };
    
    [worker requestCommand:@"register"
            withParameters:parameters
                   success:^(id result) {
                       if ([result isKindOfClass:[NSNumber class]]) {
                           NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                           [userDefaults setObject:result forKey:@"userId"];
                           [userDefaults setObject:password forKey:@"password"];
                           [userDefaults synchronize];
                           [[NSNotificationCenter defaultCenter] postNotificationName:ContentNeedUpdateNofification
                                                                               object:self];
                           [[UIApplication sharedApplication] registerForRemoteNotifications];
                       }
                   } connectionError:^(NSError *error) {
                       [self alertConnectionError];
                   } serverError:nil];
}

- (BOOL)requestPasswordRequiredCommand:(NSString *)command
                        withParameters:(NSDictionary *)parameters
                               success:(void (^)(id result))success
                       connectionError:(void (^)(NSError *error))connectionError
                           serverError:(void (^)(NSInteger error))serverError {
    
    NetworkWorker *worker = [NetworkWorker sharedNetworkWorker];
    NSDictionary *accountInfo = [self accountInfo];
    if (!accountInfo) {
        [self registerNewUser];
        return NO;
    }
    
    NSMutableDictionary *finalParameters = [[NSMutableDictionary alloc] init];
    [finalParameters addEntriesFromDictionary:accountInfo];
    [finalParameters addEntriesFromDictionary:parameters];
    
    [worker requestCommand:command
            withParameters:finalParameters
                   success:^(id result) {
                       if (success) success(result);
                   } connectionError:^(NSError *error) {
                       [self alertConnectionError];
                       if (connectionError) connectionError(error);
                   } serverError:^(NSInteger error) {
                       if (error == AGErrorWrongPassword) [self registerNewUser];
                       if (serverError) serverError(error);
                   }];
    
    return YES;
}

- (BOOL)fetchDailyDeliveryForWeek:(NSInteger)week
                          success:(void (^)())success
                  connectionError:(void (^)(NSError *error))connectionError
                      serverError:(void (^)(NSInteger error))serverError {
    
    if (week < 0) return NO;
    NSDate *fromDate = [NSDate dateFromIndex:week * kDaysOfWeek];
    NSDate *toDate = [NSDate dateFromIndex:week * kDaysOfWeek + kDaysOfWeek - 1];
    NSDictionary *parameters = @{ @"from": [fromDate toString],
                                  @"to": [toDate toString] };
    
    return [self
            requestPasswordRequiredCommand:@"daily_delivery"
            withParameters:parameters
            success:^(id result) {
                if (![result isKindOfClass:[NSArray class]]) {
                    if (serverError) serverError(AGErrorUnknownError);
                } else if ([result count]) {
                    NSManagedObjectContext *privateMOC = self.privateMOC;
                    [privateMOC performBlock:^{
                        for (id item in result) {
                            if ([item isKindOfClass:[NSDictionary class]]) {
                                NSDictionary *schedule = (NSDictionary *)item;
                                [Schedule createScheduleWithDictionary:schedule
                                                inManagedObjectContext:privateMOC
                                                      scheduleInDetail:NO
                                                       bangumiInDetial:YES];
                            }
                        }
                        [self saveContent];
                    }];
                }
                if (success) success();
            } connectionError:^(NSError *error) {
                if (connectionError) connectionError(error);
            } serverError:^(NSInteger error) {
                if (serverError) serverError(error);
            }];
}

- (BOOL)fetchMyFavoriteSuccess:(void (^)())success
               connectionError:(void (^)(NSError *error))connectionError
                   serverError:(void (^)(NSInteger error))serverError {
    
    return [self
            requestPasswordRequiredCommand:@"my_favorite"
            withParameters:@{ }
            success:^(id result) {
                if (![result isKindOfClass:[NSArray class]]) {
                    if (serverError) serverError(AGErrorUnknownError);
                } else if ([result count]) {
                    NSManagedObjectContext *privateMOC = self.privateMOC;
                    [privateMOC performBlock:^{
                        for (id item in result) {
                            if ([item isKindOfClass:[NSDictionary class]]) {
                                NSDictionary *bangumi = (NSDictionary *)item;
                                [Bangumi createBangumiWithDictionary:bangumi
                                              inManagedObjectContext:privateMOC
                                                            inDetail:NO];
                            }
                        }
                        [self saveContent];
                    }];
                    if (success) success();
                }
            } connectionError:^(NSError *error) {
                if (connectionError) connectionError(error);
            } serverError:^(NSInteger error) {
                if (serverError) serverError(error);
            }];
}

- (BOOL)fetchBangumiDetailWithBangumiId:(NSNumber *)bangumiId
                                success:(void (^)())success
                        connectionError:(void (^)(NSError *error))connectionError
                            serverError:(void (^)(NSInteger error))serverError {
    
    NSDictionary *parameters = @{ @"bangumiId": bangumiId };
    
    return [self
            requestPasswordRequiredCommand:@"bangumi_detail"
            withParameters:parameters
            success:^(id result) {
                if (![result isKindOfClass:[NSDictionary class]]) {
                    if (serverError) serverError(AGErrorUnknownError);
                }
                NSDictionary *bangumi = (NSDictionary *)result;
                NSManagedObjectContext *privateMOC = self.privateMOC;
                [privateMOC performBlock:^{
                    [Bangumi createBangumiWithDictionary:bangumi
                                  inManagedObjectContext:privateMOC
                                                inDetail:YES];
                    [self saveContent];
                }];
                if (success) success();
            } connectionError:^(NSError *error) {
                if (connectionError) connectionError(error);
            } serverError:^(NSInteger error) {
                if (serverError) serverError(error);
            }];
}

- (BOOL)fetchListAllEpisodesWithBangumiId:(NSNumber *)bangumiId
                                  success:(void (^)(NSArray *data))success
                          connectionError:(void (^)(NSError *error))connectionError
                              serverError:(void (^)(NSInteger error))serverError {
    
    NSDictionary *parameters = @{ @"bangumiId": bangumiId };
    
    return [self
            requestPasswordRequiredCommand:@"list_all_episodes"
            withParameters:parameters
            success:^(id result) {
                if (![result isKindOfClass:[NSArray class]]) {
                    if (serverError) serverError(AGErrorUnknownError);
                } else if ([result count]) {
                    NSManagedObjectContext *privateMOC = self.privateMOC;
                    [privateMOC performBlock:^{
                        for (id item in result) {
                            if ([item isKindOfClass:[NSDictionary class]]) {
                                NSMutableDictionary *scheduleDict = [(NSDictionary *)item mutableCopy];
                                NSDictionary *bangumiDict = @{ AGBangumiKeyId: bangumiId };
                                [scheduleDict setValue:bangumiDict forKey:AGScheduleKeyBangumi];
                                [Schedule createScheduleWithDictionary:scheduleDict
                                                inManagedObjectContext:privateMOC
                                                      scheduleInDetail:YES
                                                       bangumiInDetial:NO];
                            }
                        }
                        [self saveContent];
                    }];
                }
                if (success) success(result);
            } connectionError:^(NSError *error) {
                if (connectionError) connectionError(error);
            } serverError:^(NSInteger error) {
                if (serverError) serverError(error);
            }];
}

- (BOOL)fetchEpisodeDetailWithBangumiId:(NSNumber *)bangumiId
                          episodeNumber:(NSNumber *)episodeNumber
                                success:(void (^)())success
                        connectionError:(void (^)(NSError *error))connectionError
                            serverError:(void (^)(NSInteger error))serverError {
    
    NSDictionary *parameters = @{ @"bangumiId": bangumiId,
                                  @"episodeNumber": episodeNumber };
    
    return [self
            requestPasswordRequiredCommand:@"episode_detail"
            withParameters:parameters
            success:^(id result) {
                if (![result isKindOfClass:[NSArray class]]) {
                    if (serverError) serverError(AGErrorUnknownError);
                } else if ([result count]) {
                    NSManagedObjectContext *privateMOC = self.privateMOC;
                    [privateMOC performBlock:^{
                        for (id item in result) {
                            if ([item isKindOfClass:[NSDictionary class]]) {
                                NSDictionary *schedule = (NSDictionary *)item;
                                [Schedule createScheduleWithDictionary:schedule
                                                inManagedObjectContext:privateMOC
                                                      scheduleInDetail:YES
                                                       bangumiInDetial:NO];
                            }
                        }
                        [self saveContent];
                    }];
                    if (success) success();
                }
            } connectionError:^(NSError *error) {
                if (connectionError) connectionError(error);
            } serverError:^(NSInteger error) {
                if (serverError) serverError(error);
            }];
}

- (BOOL)updateMyProgressWithBangumiId:(NSNumber *)bangumiId
                           isFavorite:(NSNumber *)isFavorite
                   lastWatchedEpisode:(NSNumber *)lastWatchedEpisode
                              success:(void (^)())success
                      connectionError:(void (^)(NSError *error))connectionError
                          serverError:(void (^)(NSInteger error))serverError {
    
    NSDictionary *parameters = @{ @"bangumiId": bangumiId,
                                  @"isFavorite": isFavorite,
                                  @"lastWatchedEpisode": lastWatchedEpisode };
    
    return [self
            requestPasswordRequiredCommand:@"update_my_progress"
            withParameters:parameters
            success:^(id result) {
                NSManagedObjectContext *privateMOC = self.privateMOC;
                [privateMOC performBlock:^{
                    Bangumi *bangumi = [Bangumi getBangumiWithIdentifier:bangumiId
                                                  inManagedObjectContext:privateMOC];
                    bangumi.isFavorite = isFavorite;
                    bangumi.lastWatchedEpisode = lastWatchedEpisode;
                    [bangumi updateScheduleInfo];
                    
                    [self saveContent];
                }];
                if (success) success();
            } connectionError:^(NSError *error) {
                if (connectionError) connectionError(error);
            } serverError:^(NSInteger error) {
                if (serverError) serverError(error);
            }];
}

- (BOOL)markAllEpisodesWatchedSuccess:(void (^)())success
                      connectionError:(void (^)(NSError *error))connectionError
                          serverError:(void (^)(NSInteger error))serverError {
    
    return [self
            requestPasswordRequiredCommand:@"mark_all_episodes_watched"
            withParameters:@{ }
            success:^(id result) {
                NSManagedObjectContext *privateMOC = self.privateMOC;
                [privateMOC performBlock:^{
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kEntityNameBangumi];
                    request.predicate = [NSPredicate predicateWithFormat:@"isFavorite > 0"];
                    NSError *error = nil;
                    NSArray *matches = [privateMOC executeFetchRequest:request error:&error];
                    if (!matches || error) {
                        NSLog(@"Client database error.");
                    }
                    
                    for (Bangumi *bangumi in matches) {
                        bangumi.lastWatchedEpisode = bangumi.lastReleasedEpisode;
                        [bangumi updateScheduleInfo];
                    }
                    
                    [self saveContent];
                }];
                if (success) success();
            } connectionError:^(NSError *error) {
                if (connectionError) connectionError(error);
            } serverError:^(NSInteger error) {
                if (serverError) serverError(error);
            }];
}

#pragma mark Utility Mothods

- (NSDictionary *)accountInfo {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults valueForKey:@"userId"]) {
        return nil;
    }
    NSString *userId = [NSString stringWithFormat:@"%@", [userDefaults valueForKey:@"userId"]];
    NSString *password = [userDefaults valueForKey:@"password"];
    return @{ @"userId": userId, @"password":password };
}

- (NSString *)randomString {
    char cstring[kPasswordLength];
    for (int i = 0; i < kPasswordLength - 1; ++i) {
        int c = arc4random() % (26 + 10);
        cstring[i] = (c < 26) ? ('a' + c) : ('0' + c - 26);
    }
    cstring[kPasswordLength - 1] = '\0';
    return [NSString stringWithFormat:@"%s", cstring];
}

- (void)saveContent {
    NSManagedObjectContext *mainMOC = self.mainMOC;
    NSManagedObjectContext *privateMOC = self.privateMOC;
    NSError *error = nil;
    if (![privateMOC save:&error]) {
        NSLog(@"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
    }
    
    [mainMOC performBlock:^{
        NSError *error = nil;
        if (![mainMOC save:&error]) {
            NSLog(@"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
        }
    }];
}

@end
