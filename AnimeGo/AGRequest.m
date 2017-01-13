//
//  AGRequest.m
//  AnimeGo
//
//  Created by Chaoran Li on 2017/1/11.
//  Copyright © 2017年 Chaoran Li. All rights reserved.
//

#import "AGRequest.h"

#import "NetworkWorker.h"
#import "NetworkConstant.h"
#import "NSDate+Format.h"
#import "Bangumi+Create.h"
#import "Schedule+Create.h"
#import "AppDelegate.h"

static const NSInteger kPasswordLength = 20;
static const NSInteger kDaysOfWeek = 7;

@implementation AGRequest

#pragma mark - Private Methods

- (NSString *)p_randomPassword {
    char cstring[kPasswordLength];
    for (int i = 0; i < kPasswordLength - 1; ++i) {
        int c = arc4random() % (26 + 10);
        cstring[i] = (c < 26) ? ('a' + c) : ('0' + c - 26);
    }
    cstring[kPasswordLength - 1] = '\0';
    return [NSString stringWithFormat:@"%s", cstring];
}

- (void)p_performBlockWithPrivateMOC:(void (^)(NSManagedObjectContext *))operation {
    AppDelegate *appDelegate = (AppDelegate *) [UIApplication sharedApplication].delegate;
    NSManagedObjectContext *mainMOC = appDelegate.mainMOC;
    NSManagedObjectContext *privateMOC = appDelegate.privateMOC;
    
    [privateMOC performBlock:^{
        operation(privateMOC);
        
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
    }];
}

- (RACSignal *)p_localUserInfo {
    NSError *notRegisteredError = [NSError errorWithDomain:AGErrorDomain code:AGErrorClientNotRegistered userInfo:nil];
    
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> _Nonnull subscriber) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        if ([userDefaults valueForKey:@"userId"] && [userDefaults valueForKey:@"password"]) {
            NSString *userId = [NSString stringWithFormat:@"%@", [userDefaults valueForKey:@"userId"]];
            NSString *password = [userDefaults valueForKey:@"password"];
            [subscriber sendNext:@{ @"userId": userId, @"password":password }];
            [subscriber sendCompleted];
        } else {
            [subscriber sendError:notRegisteredError];
        }
        return nil;
    }];
}

- (RACSignal *)p_registerNewUserWithPassword:(NSString *)password {
    NetworkWorker *worker = [NetworkWorker sharedNetworkWorker];
    NSDictionary *parameters = @{ @"password": password };
    return [[worker requestCommand:@"register" withParameters:parameters uniqueToken:@"register"]
            doNext:^(id result) {
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                [userDefaults setObject:result forKey:@"userId"];
                [userDefaults setObject:password forKey:@"password"];
                [userDefaults synchronize];
                [[NSNotificationCenter defaultCenter] postNotificationName:AGContentNeedUpdateNofification
                                                                    object:self];
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            }];
}

- (RACSignal *)p_requestPasswordRequiredCommand:(NSString *)command
                                 withParameters:(NSDictionary *)parameters
                                    uniqueToken:(NSString *)uniqueToken {

    NetworkWorker *worker = [NetworkWorker sharedNetworkWorker];
    return [[[self p_localUserInfo]
            flattenMap:^__kindof RACSignal * _Nullable(NSDictionary *userInfo) {
                NSMutableDictionary *finalParameters = [[NSMutableDictionary alloc] init];
                [finalParameters addEntriesFromDictionary:userInfo];
                [finalParameters addEntriesFromDictionary:parameters];
                return [worker requestCommand:command withParameters:finalParameters uniqueToken:uniqueToken];
            }] doError:^(NSError * _Nonnull error) {
                if (error.domain == AGErrorDomain
                    && (error.code == AGErrorServerWrongPassword || error.code == AGErrorClientNotRegistered)) {

                    NSString *password = [self p_randomPassword];
                    [[self p_registerNewUserWithPassword:password] subscribeCompleted:^{ }];
                }
            }];
}

#pragma mark - Public Methods

- (RACSignal *)updateDeviceToken:(NSString *)token {
    NSDictionary *parameters = @{ @"deviceToken": token };
    return [[self p_requestPasswordRequiredCommand:@"update_device_token"
                                    withParameters:parameters
                                       uniqueToken:@"update_device_token"]
            doNext:^(id  _Nullable result) {
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                [userDefaults setObject:token forKey:@"token"];
                [userDefaults synchronize];
            }];
}

- (RACSignal *)fetchDailyDeliveryForWeek:(NSInteger)week {
    if (week < 0) return [RACSignal empty];
    
    NSDate *fromDate = [NSDate ag_dateFromIndex:week * kDaysOfWeek];
    NSDate *toDate = [NSDate ag_dateFromIndex:week * kDaysOfWeek + kDaysOfWeek - 1];
    NSDictionary *parameters = @{ @"from": [fromDate ag_toString],
                                  @"to": [toDate ag_toString] };
    
    return [[self p_requestPasswordRequiredCommand:@"daily_delivery" withParameters:parameters uniqueToken:nil]
            doNext:^(id  _Nullable result) {
                if (![result isKindOfClass:[NSArray class]] || ![result count]) return;
                [self p_performBlockWithPrivateMOC:^(NSManagedObjectContext *context) {
                    [Schedule createSchedulesWithArray:result
                               commonBangumiDictionary:nil
                                inManagedObjectContext:context
                                      scheduleInDetail:NO
                                       bangumiInDetial:YES];
                }];
            }];
}

- (RACSignal *)fetchMyFavorite {
    return [[self p_requestPasswordRequiredCommand:@"my_favorite" withParameters:@{ } uniqueToken:nil]
            doNext:^(id  _Nullable result) {
                if (![result isKindOfClass:[NSArray class]] || ![result count]) return;
                [self p_performBlockWithPrivateMOC:^(NSManagedObjectContext *context) {
                    [Bangumi createBangumisWithArray:result
                              inManagedObjectContext:context
                                            inDetail:NO];
                }];
            }];
}

- (RACSignal *)fetchBangumiDetailWithBangumiId:(NSNumber *)bangumiId {
    NSDictionary *parameters = @{ @"bangumiId": bangumiId };
    return [[self p_requestPasswordRequiredCommand:@"bangumi_detail" withParameters:parameters uniqueToken:nil]
            doNext:^(id  _Nullable result) {
                if (![result isKindOfClass:[NSDictionary class]]) return;
                NSDictionary *bangumi = (NSDictionary *)result;
                [self p_performBlockWithPrivateMOC:^(NSManagedObjectContext *context) {
                    [Bangumi createBangumiWithDictionary:bangumi
                                  inManagedObjectContext:context
                                                inDetail:YES];
                }];
            }];
}

- (RACSignal *)fetchListAllBangumis {
    NSDictionary *parameters = @{ };
    return [[self p_requestPasswordRequiredCommand:@"list_all_bangumis" withParameters:parameters uniqueToken:nil]
            doNext:^(id  _Nullable result) {
                if (![result isKindOfClass:[NSArray class]] || ![result count]) return;
                [self p_performBlockWithPrivateMOC:^(NSManagedObjectContext *context) {
                    [Bangumi createBangumisWithArray:result
                              inManagedObjectContext:context
                                            inDetail:NO];
                }];
            }];
}

- (RACSignal *)fetchListAllEpisodesWithBangumiId:(NSNumber *)bangumiId {
    NSDictionary *parameters = @{ @"bangumiId": bangumiId };
    return [[self p_requestPasswordRequiredCommand:@"list_all_episodes" withParameters:parameters uniqueToken:nil]
            doNext:^(id  _Nullable result) {
                if (![result isKindOfClass:[NSArray class]] || ![result count]) return;
                [self p_performBlockWithPrivateMOC:^(NSManagedObjectContext *context) {
                    [Schedule createSchedulesWithArray:result
                               commonBangumiDictionary:@{ AGBangumiKeyId: bangumiId }
                                inManagedObjectContext:context
                                      scheduleInDetail:YES
                                       bangumiInDetial:NO];
                }];
            }];
}

- (RACSignal *)fetchEpisodeDetailWithBangumiId:(NSNumber *)bangumiId
                                 episodeNumber:(NSNumber *)episodeNumber {
    
    NSDictionary *parameters = @{ @"bangumiId": bangumiId,
                                  @"episodeNumber": episodeNumber };
    return [[self p_requestPasswordRequiredCommand:@"episode_detail" withParameters:parameters uniqueToken:nil]
            doNext:^(id  _Nullable result) {
                if (![result isKindOfClass:[NSArray class]] || ![result count]) return;
                [self p_performBlockWithPrivateMOC:^(NSManagedObjectContext *context) {
                    [Schedule createSchedulesWithArray:result
                               commonBangumiDictionary:nil
                                inManagedObjectContext:context
                                      scheduleInDetail:YES
                                       bangumiInDetial:NO];
                }];
            }];
}

- (RACSignal *)updateMyProgressWithBangumiId:(NSNumber *)bangumiId
                           isFavorite:(NSNumber *)isFavorite
                   lastWatchedEpisode:(NSNumber *)lastWatchedEpisode {
    
    NSDictionary *parameters = @{ @"bangumiId": bangumiId,
                                  @"isFavorite": isFavorite,
                                  @"lastWatchedEpisode": lastWatchedEpisode };
    return [[self p_requestPasswordRequiredCommand:@"update_my_progress" withParameters:parameters uniqueToken:nil]
            doNext:^(id  _Nullable result) {
                [self p_performBlockWithPrivateMOC:^(NSManagedObjectContext *context) {
                    Bangumi *bangumi = [Bangumi getBangumiWithIdentifier:bangumiId
                                                  inManagedObjectContext:context];
                    bangumi.isFavorite = isFavorite;
                    bangumi.lastWatchedEpisode = lastWatchedEpisode;
                    [bangumi updateScheduleInfo];
                }];
            }];
}

- (RACSignal *)markAllEpisodesWatched {
    return [[self p_requestPasswordRequiredCommand:@"mark_all_episodes_watched" withParameters:@{ } uniqueToken:nil]
            doNext:^(id  _Nullable result) {
                [self p_performBlockWithPrivateMOC:^(NSManagedObjectContext *context) {
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:AGEntityNameBangumi];
                    request.predicate = [NSPredicate predicateWithFormat:@"isFavorite == TRUE"];
                    NSError *error = nil;
                    NSArray *matches = [context executeFetchRequest:request error:&error];
                    if (!matches || error) {
                        NSLog(@"Client database error.");
                    }
                    for (Bangumi *bangumi in matches) {
                        bangumi.lastWatchedEpisode = bangumi.lastReleasedEpisode;
                        [bangumi updateScheduleInfo];
                    }
                }];
            }];
}

@end
