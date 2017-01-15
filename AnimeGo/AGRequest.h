//
//  AGRequest.h
//  AnimeGo
//
//  Created by Chaoran Li on 2017/1/11.
//  Copyright © 2017年 Chaoran Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveObjC.h>

@interface AGRequest : NSObject

- (RACSignal *)updateDeviceToken:(NSString *)token;

- (RACSignal *)fetchDailyDeliveryForWeek:(NSInteger)week;

- (RACSignal *)fetchMyFavorite;

- (RACSignal *)fetchBangumiDetailWithBangumiId:(NSNumber *)bangumiId;

- (RACSignal *)fetchListAllBangumis;

- (RACSignal *)fetchListAllEpisodesWithBangumiId:(NSNumber *)bangumiId;

- (RACSignal *)fetchEpisodeDetailWithBangumiId:(NSNumber *)bangumiId
                                 episodeNumber:(NSNumber *)episodeNumber;

- (RACSignal *)updateMyProgressWithBangumiId:(NSNumber *)bangumiId
                                  isFavorite:(NSNumber *)isFavorite
                          lastWatchedEpisode:(NSNumber *)lastWatchedEpisode;

- (RACSignal *)markAllEpisodesWatched;

@end
