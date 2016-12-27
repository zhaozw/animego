//
//  Schedule+Create.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/28.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "Schedule+Create.h"
#import "AppInstallURL+Create.h"
#import "NetworkConstant.h"
#import "Bangumi+Create.h"
#import "NSDate+Convert.h"

NSString * const kEntityNameSchedule = @"Schedule";

static NSString *getAppName(NSString *url) {
    NSRange range = [url rangeOfString:@"://"];
    if (range.location == NSNotFound) return nil;
    return [url substringToIndex:range.location];
}

@implementation Schedule (Create)

+ (Schedule *)createScheduleWithDictionary:(NSDictionary *)scheduleDictionary
                    inManagedObjectContext:(NSManagedObjectContext *)context
                          scheduleInDetail:(BOOL)scheduleInDetail
                           bangumiInDetial:(BOOL)bangumiInDetail {
    
    NSNumber *identifier = [scheduleDictionary valueForKey:AGScheduleKeyId];
    BOOL deleted = ((NSNumber *)[scheduleDictionary valueForKey:AGScheduleKeyDeleted]).boolValue;
    Schedule *schedule = [Schedule getScheduleWithIdentifier:identifier
                                      inManagedObjectContext:context];
    
    if (deleted) {
        if (schedule) [context deleteObject:schedule];
        return nil;
    }
    
    if (!schedule) {
        schedule = [NSEntityDescription insertNewObjectForEntityForName:kEntityNameSchedule inManagedObjectContext:context];
    }
 
    schedule.bangumilastupdate = [[NSDate alloc] init];
    
    schedule.identifier = identifier;
    schedule.title = [scheduleDictionary valueForKey:AGScheduleKeyTitle];
    schedule.display = [scheduleDictionary valueForKey:AGScheduleKeyDisplay];
    schedule.releasedate = [NSDate dateFromString:[scheduleDictionary valueForKey:AGScheduleKeyReleaseDate]];
    schedule.status = [scheduleDictionary valueForKey:AGScheduleKeyStatus];
    schedule.episodenumber = [scheduleDictionary valueForKey:AGScheduleKeyEpisodeNumber];
    
    if (scheduleInDetail) {
        schedule.weburl = [scheduleDictionary valueForKey:AGScheduleKeyWebURL];
        schedule.appurl = [scheduleDictionary valueForKey:AGScheduleKeyAppURL];
        NSString *appInstallURL = [scheduleDictionary valueForKey:AGScheduleKeyAppInstallURL];
        if (appInstallURL && ![appInstallURL isEqualToString:@""]) {
            NSString *appName = getAppName(appInstallURL);
            NSDictionary *appInstallURLDictionary = @{ AGAppInstallURLKeyName: appName,
                                                       AGAppInstallURLKeyInstallURL: appInstallURL };
            AppInstallURL *appInstallURLItem = [AppInstallURL createAppInstallURLWithDictionary:appInstallURLDictionary
                                                                         inManagedObjectContext:context];
            schedule.appinstallurl = appInstallURLItem;
        }
    }
    
    if (bangumiInDetail) {
        Bangumi *bangumi = [Bangumi createBangumiWithDictionary:[scheduleDictionary valueForKey:AGScheduleKeyBangumi]
                                         inManagedObjectContext:context
                                                       inDetail:NO];
        schedule.bangumi = bangumi;
    } else {
        NSDictionary *bangumiDictionary = [scheduleDictionary valueForKey:AGScheduleKeyBangumi];
        NSNumber *bangumiId = [bangumiDictionary valueForKey:AGBangumiKeyId];
        Bangumi *bangumi = [Bangumi getBangumiWithIdentifier:bangumiId inManagedObjectContext:context];
        schedule.bangumi = bangumi;
    }
    
    return schedule;
}

+ (Schedule *)getScheduleWithIdentifier:(NSNumber *)identifier
                 inManagedObjectContext:(NSManagedObjectContext *)context {
    
    Schedule *schedule = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kEntityNameSchedule];
    request.predicate = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];

    if (error || [matches count] > 1) {
        // TODO
        NSLog(@"Client database error.");
        return nil;
    }
    
    if (!matches) return nil;
    
    if ([matches count]) {
        schedule = [matches firstObject];
    }
    
    return schedule;
}

@end
