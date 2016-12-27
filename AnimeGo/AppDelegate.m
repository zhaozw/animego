//
//  AppDelegate.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/23.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "AppDelegate.h"
#import "NotificationManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

#pragma mark - Life Cycle Methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[NotificationManager sharedNotificationManager] requestAuthorization];
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[NotificationManager sharedNotificationManager] setDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(nonnull NSError *)error {
    [[NotificationManager sharedNotificationManager] setDeviceToken:nil];
}

#pragma mark - Push Notifacation (iOS 9)

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(nonnull NSDictionary *)userInfo {
    [[NotificationManager sharedNotificationManager] handleNotification:userInfo];
}

#pragma mark - Core Data Stack

@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCorrdinator = _persistentStoreCorrdinator;
@synthesize mainMOC = _mainMOC;
@synthesize privateMOC = _privateMOC;

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    if (!_managedObjectModel) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCorrdinator {
    if (!_persistentStoreCorrdinator) {
        NSManagedObjectModel *model = self.managedObjectModel;
        _persistentStoreCorrdinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
        NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Model.sqlite"];
        NSError *error = nil;
        
        NSPersistentStore *persistentStore = [_persistentStoreCorrdinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                                       configuration:nil
                                                                                                 URL:storeURL
                                                                                             options:nil
                                                                                               error:&error];
        
        if (!persistentStore) {
            // TODO
            NSLog(@"Error initializing PersistentStoreCorrdinator: %@\n%@", [error localizedDescription], [error userInfo]);
            return nil;
        }
    }
    return _persistentStoreCorrdinator;
}

- (NSManagedObjectContext *)mainMOC {
    if (!_mainMOC) {
        NSPersistentStoreCoordinator *psc = self.persistentStoreCorrdinator;
        if (!psc) return nil;
        _mainMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_mainMOC setPersistentStoreCoordinator:psc];
    }
    return _mainMOC;
}

- (NSManagedObjectContext *)privateMOC {
    if (!_privateMOC) {
        NSManagedObjectContext *mainMOC = self.mainMOC;
        if (!mainMOC) return nil;
        _privateMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_privateMOC setParentContext:mainMOC];
    }
    return _privateMOC;
}

@end
