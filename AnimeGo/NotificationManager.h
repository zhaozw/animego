//
//  NotificationManager.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/6.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

extern NSString * const JumpToEpisodeNotification;

@interface NotificationManager : NSObject <UNUserNotificationCenterDelegate>

@property (nonatomic) BOOL isJumpToEpisodeNotificationHandled;
@property (nonatomic) NSNumber *jumpToEpisodeNotificationDestinationBangumiIdentifier;
@property (nonatomic, readonly) BOOL enable;

+ (NotificationManager *)sharedNotificationManager;

- (void)requestAuthorization;
- (void)setDeviceToken:(NSData *)token;
- (void)getNotificationSettingsWithCompletionHandler:(void (^)(BOOL granted))handler;

- (void)handleNotification:(NSDictionary *)notification;

@end
