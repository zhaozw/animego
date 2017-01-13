//
//  Bangumi+Create.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/28.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "Bangumi+CoreDataClass.h"

extern NSString * const AGEntityNameBangumi;

@interface Bangumi (Create)

+ (Bangumi *)createBangumiWithDictionary:(NSDictionary *)bangumiDictionary
                  inManagedObjectContext:(NSManagedObjectContext *)context
                                inDetail:(BOOL)detail;

+ (Bangumi *)getBangumiWithIdentifier:(NSNumber *)identifier
               inManagedObjectContext:(NSManagedObjectContext *)context;

+ (void)createBangumisWithArray:(NSArray *)bangumiArray
         inManagedObjectContext:(NSManagedObjectContext *)context
                       inDetail:(BOOL)detail;

- (void)updateScheduleInfo;

@end
