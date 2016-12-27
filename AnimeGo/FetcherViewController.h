//
//  FetcherViewController.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/5.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface FetcherViewController : UIViewController <NSFetchedResultsControllerDelegate>

@property (strong, readonly, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (weak, nonatomic) NSManagedObjectContext *mainMOC;

- (NSFetchRequest *)fetchRequest;
- (NSTimeInterval)autoRefreshTimeInterval;
- (BOOL)hasRefreshButton;
- (void)fetchRemoteData;
- (void)updateUI;
- (BOOL)alertNetworkError;

- (void)touchRefreshButton;
- (void)didBecomeActive;
- (void)willResignActive;
- (void)contentNeedUpdateNofification;
- (void)doJumpToEpisode;

- (BOOL)fetchDailyDeliveryForWeek:(NSInteger)week
                          success:(void (^)())success
                  connectionError:(void (^)(NSError *error))connectionError
                      serverError:(void (^)(NSInteger error))serverError;

- (BOOL)fetchMyFavoriteSuccess:(void (^)())success
               connectionError:(void (^)(NSError *error))connectionError
                   serverError:(void (^)(NSInteger error))serverError;

- (BOOL)fetchBangumiDetailWithBangumiId:(NSNumber *)bangumiId
                                success:(void (^)())success
                        connectionError:(void (^)(NSError *error))connectionError
                            serverError:(void (^)(NSInteger error))serverError;

- (BOOL)fetchListAllEpisodesWithBangumiId:(NSNumber *)bangumiId
                                  success:(void (^)(NSArray *data))success
                          connectionError:(void (^)(NSError *error))connectionError
                              serverError:(void (^)(NSInteger error))serverError;

- (BOOL)fetchEpisodeDetailWithBangumiId:(NSNumber *)bangumiId
                          episodeNumber:(NSNumber *)episodeNumber
                                success:(void (^)())success
                        connectionError:(void (^)(NSError *error))connectionError
                            serverError:(void (^)(NSInteger error))serverError;
- (BOOL)updateMyProgressWithBangumiId:(NSNumber *)bangumiId
                           isFavorite:(NSNumber *)isFavorite
                   lastWatchedEpisode:(NSNumber *)lastWatchedEpisode
                              success:(void (^)())success
                      connectionError:(void (^)(NSError *error))connectionError
                          serverError:(void (^)(NSInteger error))serverError;

- (BOOL)markAllEpisodesWatchedSuccess:(void (^)())success
                      connectionError:(void (^)(NSError *error))connectionError
                          serverError:(void (^)(NSInteger error))serverError;

@end
