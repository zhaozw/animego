//
//  AppDelegate.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/23.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

extern NSString * const AGDynamicShortcutKeyBangumiIdentifer;
extern NSString * const AGSpotlightIdentifierPrefix;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;

@property (nonatomic, strong, readonly) NSManagedObjectContext *mainMOC;
@property (nonatomic, strong, readonly) NSManagedObjectContext *privateMOC;
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCorrdinator;

@end

