//
//  AppDelegate+Shortcut.m
//  AnimeGo
//
//  Created by Chaoran Li on 2017/1/15.
//  Copyright © 2017年 Chaoran Li. All rights reserved.
//

#import "AppDelegate+Shortcut.h"

#import "AppDelegate+CoreData.h"
#import "Bangumi+Create.h"
#import "Schedule+Create.h"
#import "NetworkConstant.h"

static NSString * const kShortcutTypeSchedule = @"com.lainiwakura.animego.shortcut.schedule";

@implementation AppDelegate (Shortcut)

#pragma mark - Private Methods

- (UIApplicationShortcutItem *)p_shortcutItemWithSchedule:(Schedule *)schedule {
    NSString *subtitle = [NSString stringWithFormat:@"第%@集 %@", schedule.episodeNumber, schedule.title];
    NSDictionary *userInfo = @{ AGDynamicShortcutKeyBangumiIdentifer: schedule.bangumi.identifier };
    UIApplicationShortcutItem *shortcut = [[UIApplicationShortcutItem alloc] initWithType:kShortcutTypeSchedule
                                                                           localizedTitle:schedule.bangumi.title
                                                                        localizedSubtitle:subtitle
                                                                                     icon:nil
                                                                                 userInfo:userInfo];
    return shortcut;
}

#pragma mark - Public Methods

- (void)addShortcutItems {
    [[self asyncOperationWithPrivateMOC:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:AGEntityNameSchedule];
        request.predicate = [NSPredicate
                             predicateWithFormat:@"bangumi.isFavorite == TRUE AND status == %@", @(AGScheduleStatusReleased)];
        NSSortDescriptor *releaseDateSort = [NSSortDescriptor sortDescriptorWithKey:@"releaseDate" ascending:NO];
        [request setSortDescriptors:@[ releaseDateSort ]];
        
        NSError *error = nil;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if (!matches || error) {
            NSLog(@"Client database error.");
            return;
        }
        
        NSMutableArray *shortcutArray = [[NSMutableArray alloc] init];
        if ([matches count] >= 1) [shortcutArray addObject:[self p_shortcutItemWithSchedule:matches[0]]];
        if ([matches count] >= 2) [shortcutArray addObject:[self p_shortcutItemWithSchedule:matches[1]]];
        if ([matches count] >= 3) [shortcutArray addObject:[self p_shortcutItemWithSchedule:matches[2]]];
        [UIApplication sharedApplication].shortcutItems = shortcutArray;
    }] subscribeCompleted:^{ }];
}

@end
