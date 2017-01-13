//
//  Schedule+Create.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/28.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "Schedule+Create.h"

#import <UIKit/UIKit.h>
#import "NetworkConstant.h"
#import "Bangumi+Create.h"
#import "NSDate+Format.h"

NSString * const AGEntityNameSchedule = @"Schedule";

@implementation Schedule (Create)

#pragma mark - Class Methods

+ (Schedule *)createScheduleWithDictionary:(NSDictionary *)scheduleDictionary
                    inManagedObjectContext:(NSManagedObjectContext *)context
                          scheduleInDetail:(BOOL)scheduleInDetail
                           bangumiInDetial:(BOOL)bangumiInDetail {
    
    NSNumber *identifier = scheduleDictionary[AGScheduleKeyId];
    BOOL deleted = ((NSNumber *) (scheduleDictionary[AGScheduleKeyDeleted])).boolValue;
    Schedule *schedule = [Schedule getScheduleWithIdentifier:identifier
                                      inManagedObjectContext:context];
    
    if (deleted) {
        if (schedule) [context deleteObject:schedule];
        return nil;
    }
    
    if (!schedule) {
        schedule = [NSEntityDescription insertNewObjectForEntityForName:AGEntityNameSchedule
                                                 inManagedObjectContext:context];
    }
 
    [schedule p_setValuesWithNetworkDictionary:scheduleDictionary
                       commonBangumiDictionary:nil
                        inManagedObjectContext:context
                              scheduleInDetail:scheduleInDetail
                               bangumiInDetial:bangumiInDetail];
    
    return schedule;
}

+ (Schedule *)getScheduleWithIdentifier:(NSNumber *)identifier
                 inManagedObjectContext:(NSManagedObjectContext *)context {
    
    Schedule *schedule = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:AGEntityNameSchedule];
    request.predicate = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];

    if (!matches || error || [matches count] > 1) {
        NSLog(@"Client database error.");
        return nil;
    }
    
    if ([matches count]) {
        schedule = [matches firstObject];
    }
    
    return schedule;
}

+ (void)createSchedulesWithArray:(NSArray *)scheduleArray
         commonBangumiDictionary:(NSDictionary *)bangumiDictionary
          inManagedObjectContext:(NSManagedObjectContext *)context
                scheduleInDetail:(BOOL)scheduleInDetail
                 bangumiInDetial:(BOOL)bangumiInDetail {
    
    NSMutableArray *idArray = [[NSMutableArray alloc] init];
    for (NSDictionary *scheduleDictionary in scheduleArray) {
        [idArray addObject:scheduleDictionary[AGScheduleKeyId]];
    }
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:AGEntityNameSchedule];
    request.predicate = [NSPredicate predicateWithFormat:@"identifier IN %@", idArray];
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || error) {
        NSLog(@"Client database error.");
        return;
    }
    
    for (NSDictionary *scheduleDictionary in scheduleArray) {
        NSNumber *identifier = scheduleDictionary[AGScheduleKeyId];
        BOOL deleted = ((NSNumber *) (scheduleDictionary[AGScheduleKeyDeleted])).boolValue;
        
        Schedule *schedule = nil;
        for (Schedule *match in matches) {
            if ([match.identifier isEqual:identifier]) {
                schedule = match;
                break;
            }
        }
        
        if (deleted) {
            if (schedule) [context deleteObject:schedule];
            continue;
        }
        
        if (!schedule) {
            schedule = [NSEntityDescription insertNewObjectForEntityForName:AGEntityNameSchedule
                                                     inManagedObjectContext:context];
        }
        
        [schedule p_setValuesWithNetworkDictionary:scheduleDictionary
                           commonBangumiDictionary:bangumiDictionary
                            inManagedObjectContext:context
                                  scheduleInDetail:scheduleInDetail
                                   bangumiInDetial:bangumiInDetail];
    }
}

#pragma mark - Private Methods

- (void)p_setValuesWithNetworkDictionary:(NSDictionary *)scheduleDictionary
                 commonBangumiDictionary:(NSDictionary *)bangumiDictionary
                  inManagedObjectContext:(NSManagedObjectContext *)context
                        scheduleInDetail:(BOOL)scheduleInDetail
                         bangumiInDetial:(BOOL)bangumiInDetail {
    
    self.bangumiLastUpdate = [[NSDate alloc] init];
    
    self.identifier = scheduleDictionary[AGScheduleKeyId];
    self.title = scheduleDictionary[AGScheduleKeyTitle];
    self.display = scheduleDictionary[AGScheduleKeyDisplay];
    self.releaseDate = [NSDate ag_dateFromString:scheduleDictionary[AGScheduleKeyReleaseDate]];
    self.status = scheduleDictionary[AGScheduleKeyStatus];
    self.episodeNumber = scheduleDictionary[AGScheduleKeyEpisodeNumber];
    
    if (scheduleInDetail) {
        self.webURL = scheduleDictionary[AGScheduleKeyWebURL];
        self.phoneAppURL = scheduleDictionary[AGScheduleKeyPhoneAppURL];
        self.padAppURL = scheduleDictionary[AGScheduleKeyPadAppURL];
    }
    
    if (!bangumiDictionary) bangumiDictionary = scheduleDictionary[AGScheduleKeyBangumi];
    
    if (bangumiInDetail) {
        Bangumi *bangumi = [Bangumi createBangumiWithDictionary:bangumiDictionary
                                         inManagedObjectContext:context
                                                       inDetail:NO];
        self.bangumi = bangumi;
    } else {
        NSNumber *bangumiId = bangumiDictionary[AGBangumiKeyId];
        Bangumi *bangumi = [Bangumi getBangumiWithIdentifier:bangumiId inManagedObjectContext:context];
        self.bangumi = bangumi;
    }
}

#pragma mark - Public Methods

- (NSString *)suitableAppURL {
    UIUserInterfaceIdiom deviceType = [[UIDevice currentDevice] userInterfaceIdiom];
    return (deviceType == UIUserInterfaceIdiomPad) ? self.padAppURL : self.phoneAppURL;
}

@end
