//
//  AppDelegate+Spotlight.m
//  AnimeGo
//
//  Created by Chaoran Li on 2017/1/15.
//  Copyright © 2017年 Chaoran Li. All rights reserved.
//

#import "AppDelegate+Spotlight.h"

#import <CoreSpotlight/CoreSpotlight.h>
#import "AppDelegate+CoreData.h"
#import "Bangumi+Create.h"
#import "NetworkConstant.h"

static NSString * const kSpotlightType = @"com.lainiwakura.animego.spotlight.schedule";
static NSString * const kSpotlightDomain = @"com.lainiwakura.animego.spotlight.domain";

@implementation AppDelegate (Spotlight)

#pragma mark - Private Methods

- (CSSearchableItem *)p_spotlightItemWithSchedule:(Bangumi *)bangumi {
    CSSearchableItemAttributeSet *attributeSet = [[CSSearchableItemAttributeSet alloc]
                                                  initWithItemContentType:kSpotlightType];
    
    attributeSet.title = bangumi.title;
    switch (bangumi.status.integerValue) {
        case AGBangumiStatusNotReleased:
            attributeSet.contentDescription = [NSString stringWithFormat:@"尚未开播"];
            break;
        case AGBangumiStatusReleased:
            attributeSet.contentDescription = [NSString stringWithFormat:@"已连载至第%@话", bangumi.lastReleasedEpisode];
            break;
        case AGBangumiStatusOver:
            attributeSet.contentDescription = [NSString stringWithFormat:@"共%@话 (已完结)", bangumi.lastReleasedEpisode];
            break;
    }
    attributeSet.contactKeywords = @[ bangumi.title ];

    NSString *itemIdentifier = [NSString stringWithFormat:@"%@.%@", AGSpotlightIdentifierPrefix, bangumi.identifier];
    CSSearchableItem *searchableItem = [[CSSearchableItem alloc] initWithUniqueIdentifier:itemIdentifier
                                                                         domainIdentifier:kSpotlightDomain
                                                                             attributeSet:attributeSet];
    return searchableItem;
}

#pragma mark - Public Methods

- (void)addSpotlightItems {
    [[self asyncOperationWithPrivateMOC:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:AGEntityNameBangumi];

        NSError *error = nil;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if (!matches || error) {
            NSLog(@"Client database error.");
            return;
        }
        
        NSMutableArray *itemArray = [[NSMutableArray alloc] init];
        for (Bangumi *bangumi in matches) {
            [itemArray addObject:[self p_spotlightItemWithSchedule:bangumi]];
        }
        
        [[CSSearchableIndex defaultSearchableIndex]
         deleteSearchableItemsWithDomainIdentifiers:@ [ kSpotlightDomain ]
         completionHandler:^(NSError * _Nullable error) {
             if (error) {
                 NSLog(@"Failed to delete spotlight items: %@", error);
                 return;
             }

             [[CSSearchableIndex defaultSearchableIndex]
              indexSearchableItems:itemArray
              completionHandler:^(NSError * _Nullable error) {
                  if (error) NSLog(@"Failed to add spotlight items: %@", error);
              }];
         }];
    }] subscribeCompleted:^{ }];
}

@end
