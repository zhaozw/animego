//
//  Schedule+Create.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/28.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "Schedule+CoreDataClass.h"

extern NSString * const kEntityNameSchedule;

@interface Schedule (Create)

+ (Schedule *)createScheduleWithDictionary:(NSDictionary *)scheduleDictionary
                    inManagedObjectContext:(NSManagedObjectContext *)context
                          scheduleInDetail:(BOOL)scheduleInDetail
                           bangumiInDetial:(BOOL)bangumiInDetai;

+ (Schedule *)getScheduleWithIdentifier:(NSNumber *)identifier
                 inManagedObjectContext:(NSManagedObjectContext *)context;

@end
