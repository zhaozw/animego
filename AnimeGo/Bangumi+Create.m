//
//  Bangumi+Create.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/28.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "Bangumi+Create.h"

#import "Schedule+Create.h"
#import "NetworkConstant.h"

NSString * const AGEntityNameBangumi = @"Bangumi";

@implementation Bangumi (Create)

#pragma mark - Class Methods

+ (Bangumi *)createBangumiWithDictionary:(NSDictionary *)bangumiDictionary
                  inManagedObjectContext:(NSManagedObjectContext *)context
                                inDetail:(BOOL)detail {
    
    NSNumber *identifier = bangumiDictionary[AGBangumiKeyId];
    BOOL deleted = ((NSNumber *) (bangumiDictionary[AGBangumiKeyDeleted])).boolValue;
    
    Bangumi *bangumi = [Bangumi getBangumiWithIdentifier:identifier
                                  inManagedObjectContext:context];
    
    if (deleted) {
        if (bangumi) [context deleteObject:bangumi];
        return nil;
    }
    
    if (!bangumi) {
        bangumi = [NSEntityDescription insertNewObjectForEntityForName:AGEntityNameBangumi inManagedObjectContext:context];
    }
    
    [bangumi p_setValuesWithNetworkDictionary:bangumiDictionary
                       inManagedObjectContext:context
                                     inDetail:detail];
    return bangumi;
}

+ (Bangumi *)getBangumiWithIdentifier:(NSNumber *)identifier
               inManagedObjectContext:(NSManagedObjectContext *)context {
    
    Bangumi *bangumi = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:AGEntityNameBangumi];
    request.predicate = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || error || [matches count] > 1) {
        NSLog(@"Client database error.");
        return nil;
    }
    
    if ([matches count]) {
        bangumi = [matches firstObject];
    }
    
    return bangumi;
}

+ (void)createBangumisWithArray:(NSArray *)bangumiArray
         inManagedObjectContext:(NSManagedObjectContext *)context
                       inDetail:(BOOL)detail {
    
    NSMutableArray *idArray = [[NSMutableArray alloc] init];
    for (NSDictionary *bangumiDictionary in bangumiArray) {
        [idArray addObject:bangumiDictionary[AGBangumiKeyId]];
    }
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:AGEntityNameBangumi];
    request.predicate = [NSPredicate predicateWithFormat:@"identifier IN %@", idArray];
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || error) {
        NSLog(@"Client database error.");
        return;
    }
    
    for (NSDictionary *bangumiDictionary in bangumiArray) {
        NSNumber *identifier = bangumiDictionary[AGBangumiKeyId];
        BOOL deleted = ((NSNumber *) (bangumiDictionary[AGBangumiKeyDeleted])).boolValue;
        
        Bangumi *bangumi = nil;
        for (Bangumi *match in matches) {
            if ([match.identifier isEqual:identifier]) {
                bangumi = match;
                break;
            }
        }
        
        if (deleted) {
            if (bangumi) [context deleteObject:bangumi];
            continue;
        }
        
        if (!bangumi) {
            bangumi = [NSEntityDescription insertNewObjectForEntityForName:AGEntityNameBangumi
                                                    inManagedObjectContext:context];
        }
        
        [bangumi p_setValuesWithNetworkDictionary:bangumiDictionary
                           inManagedObjectContext:context
                                         inDetail:detail];
    }
}

#pragma mark - Private Methods

- (void)p_setValuesWithNetworkDictionary:(NSDictionary *)bangumiDictionary
                  inManagedObjectContext:(NSManagedObjectContext *)context
                                inDetail:(BOOL)detail {
    
    self.identifier = bangumiDictionary[AGBangumiKeyId];
    self.title = bangumiDictionary[AGBangumiKeyTitle];
    self.hot = bangumiDictionary[AGBangumiKeyHot];
    self.coverImageURL = bangumiDictionary[AGBangumiKeyCoverImageURL];
    self.isFavorite = bangumiDictionary[AGBangumiKeyIsFavorite];
    self.releaseWeekday = bangumiDictionary[AGBangumiKeyReleaseWeekdays];
    self.totalEpisodes = bangumiDictionary[AGBangumiKeyTotalEpisodes];
    self.firstReleasedEpisode = bangumiDictionary[AGBangumiKeyFirstReleasedEpisode];
    self.lastReleasedEpisode = bangumiDictionary[AGBangumiKeyLastReleasedEpisode];
    self.lastWatchedEpisode = bangumiDictionary[AGBangumiKeyLastWatchedEpisode];
    self.status = bangumiDictionary[AGBangumiKeyStatus];
    
    if (detail) {
        self.largeImageURL = bangumiDictionary[AGBangumiKeyLargeImageURL];
        self.stuff = bangumiDictionary[AGBangumiKeyStuff];
        self.characterVoice = bangumiDictionary[AGBangumiKeyCharacterVoice];
        self.synopsis = bangumiDictionary[AGBangumiKeySynopsis];
    }
    
    [self updateScheduleInfo];
}

#pragma mark - Public Methods

- (void)updateScheduleInfo {
    NSInteger priority = 0;
    if (self.isFavorite.boolValue) {
        priority = (self.lastReleasedEpisode > self.lastWatchedEpisode) ? 2 : 1;
    }
    self.priority = @(priority);
    
    NSDate *now = [[NSDate alloc] init];
    for (Schedule *schedule in self.schedule) {
        schedule.bangumiLastUpdate = now;
    }
}

@end
