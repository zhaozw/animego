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

NSString * const kEntityNameBangumi = @"Bangumi";

@implementation Bangumi (Create)

+ (Bangumi *)createBangumiWithDictionary:(NSDictionary *)bangumiDictionary
                  inManagedObjectContext:(NSManagedObjectContext *)context
                                inDetail:(BOOL)detail {
    
    NSNumber *identifier = [bangumiDictionary valueForKey:AGBangumiKeyId];
    BOOL deleted = ((NSNumber *)[bangumiDictionary valueForKey:AGBangumiKeyDeleted]).boolValue;
    
    Bangumi *bangumi = [Bangumi getBangumiWithIdentifier:identifier
                                  inManagedObjectContext:context];

    if (deleted) {
        if (bangumi) [context deleteObject:bangumi];
        return nil;
    }
    
    if (!bangumi) {
        bangumi = [NSEntityDescription insertNewObjectForEntityForName:kEntityNameBangumi inManagedObjectContext:context];
    }
    
    bangumi.identifier = identifier;
    bangumi.title = [bangumiDictionary valueForKey:AGBangumiKeyTitle];
    bangumi.hot = [bangumiDictionary valueForKey:AGBangumiKeyHot];
    bangumi.coverImageURL = [bangumiDictionary valueForKey:AGBangumiKeyCoverImageURL];
    bangumi.isFavorite = [bangumiDictionary valueForKey:AGBangumiKeyIsFavorite];
    bangumi.releaseWeekday = [bangumiDictionary valueForKey:AGBangumiKeyReleaseWeekdays];
    bangumi.totalEpisodes = [bangumiDictionary valueForKey:AGBangumiKeyTotalEpisodes];
    bangumi.firstReleasedEpisode = [bangumiDictionary valueForKey:AGBangumiKeyFirstReleasedEpisode];
    bangumi.lastReleasedEpisode = [bangumiDictionary valueForKey:AGBangumiKeyLastReleasedEpisode];
    bangumi.lastWatchedEpisode = [bangumiDictionary valueForKey:AGBangumiKeyLastWatchedEpisode];
    
    bangumi.status = [bangumiDictionary valueForKey:AGBangumiKeyStatus];
    
    if (detail) {
        bangumi.largeImageURL = [bangumiDictionary valueForKey:AGBangumiKeyLargeImageURL];
        bangumi.stuff = [bangumiDictionary valueForKey:AGBangumiKeyStuff];
        bangumi.characterVoice = [bangumiDictionary valueForKey:AGBangumiKeyCharacterVoice];
        bangumi.synopsis = [bangumiDictionary valueForKey:AGBangumiKeySynopsis];
    }
    
    [bangumi updateScheduleInfo];
    return bangumi;
}

+ (Bangumi *)getBangumiWithIdentifier:(NSNumber *)identifier
               inManagedObjectContext:(NSManagedObjectContext *)context {
    
    Bangumi *bangumi = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kEntityNameBangumi];
    request.predicate = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || error || [matches count] > 1) {
        // TODO
        NSLog(@"Client database error.");
        return nil;
    }
    
    if ([matches count]) {
        bangumi = [matches firstObject];
    }
    
    return bangumi;
}

- (void)updateScheduleInfo {
    NSInteger priority = 0;
    if (self.isFavorite.integerValue > 0) {
        priority = (self.lastReleasedEpisode > self.lastWatchedEpisode) ? 2 : 1;
    }
    self.priority = @(priority);
    for (Schedule *schedule in self.schedule) {
        schedule.bangumiLastUpdate = [[NSDate alloc] init];
    }
}

@end
