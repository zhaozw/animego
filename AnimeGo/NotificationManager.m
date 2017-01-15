//
//  NotificationManager.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/6.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "NotificationManager.h"

#import <UIKit/UIKit.h>
#import "AGRequest.h"
#import "NetworkConstant.h"

NSString * const AGJumpToPageNotification          = @"AGJumpToPageNotification";
NSString * const AGContentNeedUpdateNofification   = @"AGContentNeedUpdateNofification";
NSString * const AGContentNeedReOrderNofification  = @"AGContentNeedReOrderNofification";

static NSString * const kNatificationKeyBangumiIdentifier = @"bangumi_id";
static const NSTimeInterval kRetryInterval = 2.0;

@interface NotificationManager ()

@property (nonatomic, assign, readwrite) BOOL enable;

@end

@implementation NotificationManager

#pragma mark - Singleton

+ (NotificationManager *)sharedNotificationManager {
    static NotificationManager *sharedNotificationManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedNotificationManager = [[NotificationManager alloc] init];
        sharedNotificationManager.enable = NO;
        sharedNotificationManager.jumpDestinationPageIdentifier = nil;
        sharedNotificationManager.jumpStatus = AGJumpByNotaficationStatusCompleted;
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0) {
            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
            center.delegate = sharedNotificationManager;
        }
    });
    return sharedNotificationManager;
}

#pragma mark - <UNUserNotificationCenterDelegate>

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:AGContentNeedUpdateNofification object:self];
    completionHandler(UNNotificationPresentationOptionAlert);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)())completionHandler {
    
    if ([response.actionIdentifier isEqualToString:UNNotificationDismissActionIdentifier]) {
        // The user dismissed the notification without taking action.
        //
    } else if ([response.actionIdentifier isEqualToString:UNNotificationDefaultActionIdentifier]) {
        UNNotification *notification = response.notification;
        [self p_jumpByNotifacation:notification.request.content.userInfo];
    }
    
    completionHandler();
}

#pragma mark - Public Methods

- (void)requestAuthorization {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge
                                                 + UNAuthorizationOptionAlert
                                                 + UNAuthorizationOptionSound)
                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                  if (granted) {
                                      [[UIApplication sharedApplication] registerForRemoteNotifications];
                                  }
                              }];
    } else {
        UIUserNotificationType type = UIUserNotificationTypeBadge | UIUserNotificationTypeAlert | UIUserNotificationTypeSound;
        UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:type
                                                                                             categories:nil];
        UIApplication *application = [UIApplication sharedApplication];
        [application registerUserNotificationSettings:notificationSettings];
        [application registerForRemoteNotifications];
    }
}

- (void)getNotificationSettingsWithCompletionHandler:(void (^)(BOOL granted))handler {
    [self requestAuthorization];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            if (settings.alertSetting == UNNotificationSettingEnabled) {
                [self p_enableRemoteNotificationFeatures];
                handler(YES);
            } else {
                [self p_disableRemoteNotificationFeatures];
                handler(NO);
            }
        }];
    } else {
        if ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications]) {
            [self p_enableRemoteNotificationFeatures];
            handler(YES);
        } else {
            [self p_disableRemoteNotificationFeatures];
            handler(NO);
        }
    }
}

- (void)setDeviceToken:(NSData *)token {
    NSString *stringToken;
    if (token) {
        [self p_enableRemoteNotificationFeatures];
        stringToken = [[[[token description]
                         stringByReplacingOccurrencesOfString: @"<" withString: @""]
                        stringByReplacingOccurrencesOfString: @">" withString: @""]
                       stringByReplacingOccurrencesOfString: @" " withString: @""];
    } else {
        [self p_disableRemoteNotificationFeatures];
        stringToken = @"";
    }
    [self p_forwardTokenToServer:stringToken tryTimes:0];
}

- (void)handleNotification:(NSDictionary *)userInfo {
    // For iOS 9 Only
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0) return;
    
    NSString *message = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"新动画更新"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"查看" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              [self p_jumpByNotifacation:userInfo];
                                                          }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) { }];
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    UIApplication *application = [UIApplication sharedApplication];
    UIViewController *presentedVC = application.delegate.window.rootViewController;
    if (presentedVC.presentedViewController) {
        presentedVC = presentedVC.presentedViewController;
    }
    [presentedVC presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Private Methods

- (void)p_forwardTokenToServer:(NSString *)token
                      tryTimes:(NSInteger)tryTimes {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *oldToken = [userDefaults valueForKey:@"token"];
    if (oldToken && [oldToken isEqualToString:token]) return;
    
    void (^tryBlock)() = ^{
        AGRequest *request = [[AGRequest alloc] init];
        [[[request updateDeviceToken:token]
          deliverOn:[RACScheduler mainThreadScheduler]]
         subscribeError:^(NSError * _Nullable error) {
             [self p_forwardTokenToServer:token tryTimes:tryTimes + 1];
         } completed:^{ }];
    };
    
    if (tryTimes == 0) {
        tryBlock();
    } else {
        NSTimeInterval nextRetryInterval = pow(kRetryInterval, tryTimes);
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t) (nextRetryInterval * NSEC_PER_SEC));
        dispatch_after(delay, dispatch_get_main_queue(), ^(void) {
            tryBlock();
        });
    }
}

- (void)p_jumpByNotifacation:(NSDictionary *)remoteNotification {
    if (remoteNotification) {
        id info = remoteNotification[kNatificationKeyBangumiIdentifier];
        if (info && [info isKindOfClass:[NSNumber class]]) {
            self.jumpDestinationPageIdentifier = (NSNumber *)info;
            self.jumpStatus = AGJumpByNotaficationStatusUntreated;
        } else {
            self.jumpDestinationPageIdentifier = nil;
            self.jumpStatus = AGJumpByNotaficationStatusCompleted;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:AGJumpToPageNotification object:self];
    }
}

- (void)p_enableRemoteNotificationFeatures {
    self.enable = YES;
}

- (void)p_disableRemoteNotificationFeatures {
    self.enable = NO;
}

@end
