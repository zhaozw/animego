//
//  NotificationManager.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/6.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

typedef NS_ENUM(NSInteger, AGJumpByNotaficationStatus) {
    AGJumpByNotaficationStatusUntreated = 1,
    AGJumpByNotaficationStatusHandling  = 2,
    AGJumpByNotaficationStatusCompleted = 3
};

extern NSString * const AGJumpToPageNotification;
extern NSString * const AGContentNeedUpdateNofification;
extern NSString * const AGContentNeedReOrderNofification;

@interface NotificationManager : NSObject <UNUserNotificationCenterDelegate>

@property (nonatomic, assign) AGJumpByNotaficationStatus jumpStatus;
@property (nonatomic, strong) NSNumber *jumpDestinationPageIdentifier;
@property (nonatomic, assign, readonly) BOOL enable;

+ (NotificationManager *)sharedNotificationManager;

- (void)requestAuthorization;
- (void)getNotificationSettingsWithCompletionHandler:(void (^)(BOOL granted))handler;
- (void)setDeviceToken:(NSData *)token;
- (void)handleNotification:(NSDictionary *)notification;

@end
