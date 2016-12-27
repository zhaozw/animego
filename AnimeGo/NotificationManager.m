//
//  NotificationManager.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/6.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "NotificationManager.h"

#import <UIKit/UIKit.h>
#import "NetworkWorker.h"
#import "NetworkConstant.h"

NSString * const JumpToEpisodeNotification = @"JumpToEpisodeNotification";

static NSString * const kNatificationKeyBangumiIdentifier = @"bangumi_id";

@interface NotificationManager ()

@property (nonatomic, readwrite) BOOL enable;
@property (nonatomic, strong) NSTimer *delayRequest;

@end

@implementation NotificationManager

#pragma mark - Singleton

+ (NotificationManager *)sharedNotificationManager {
    static NotificationManager *sharedNotificationManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedNotificationManager = [[NotificationManager alloc] init];
        sharedNotificationManager.enable = NO;
        sharedNotificationManager.jumpToEpisodeNotificationDestinationBangumiIdentifier = nil;
        sharedNotificationManager.isJumpToEpisodeNotificationHandled = YES;
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0) {
            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
            center.delegate = sharedNotificationManager;
        }
    });
    return sharedNotificationManager;
}

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ContentNeedUpdateNofification object:self];
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
        [self jumpByNotifacation:notification.request.content.userInfo];
    }
    
    completionHandler();
}

#pragma mark - Public Methods

- (void)handleNotification:(NSDictionary *)userInfo {
    // For iOS 9 Only
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0) return;
    
    NSString *message = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"新动画更新"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"查看" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              [[NotificationManager sharedNotificationManager] jumpByNotifacation:userInfo];
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

- (void)setDeviceToken:(NSData *)token {
    NSString *stringToken;
    if (token) {
        stringToken = [[[[token description]
                         stringByReplacingOccurrencesOfString: @"<" withString: @""]
                        stringByReplacingOccurrencesOfString: @">" withString: @""]
                       stringByReplacingOccurrencesOfString: @" " withString: @""];
    } else {
        [self disableRemoteNotificationFeatures];
        stringToken = @"";
    }
    [self forwardTokenToServer:stringToken delay:0];
}

- (void)forwardTokenToServer:(NSString *)token
                       delay:(NSTimeInterval)delay {
    
    NetworkWorker *worker = [NetworkWorker sharedNetworkWorker];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults valueForKey:@"userId"]) return;
    NSString *userId = [NSString stringWithFormat:@"%@", [userDefaults valueForKey:@"userId"]];
    NSString *password = [userDefaults valueForKey:@"password"];
    
    NSDictionary *parameters = @{ @"userId": userId,
                                  @"password": password,
                                  @"deviceToken": token };
    
    void (^errorHandler)() = ^{
        [self disableRemoteNotificationFeatures];
        NSTimeInterval nextDelay = delay * 2;
        if (nextDelay <= 0) nextDelay = 1;
        [self forwardTokenToServer:token delay:nextDelay];
    };
    
    void (^doRequest)() = ^{
        [worker requestCommand:@"update_device_token"
                withParameters:parameters
                       success:^(id result) {
                           [self enableRemoteNotificationFeatures];
                       } connectionError:^(NSError *error) {
                           errorHandler();
                       } serverError:^(NSInteger error) {
                           errorHandler();
                       }];
    };
    
    [self.delayRequest invalidate];
    if (delay <= 0) {
        doRequest();
    } else {
        self.delayRequest = [NSTimer timerWithTimeInterval:delay
                                                   repeats:NO
                                                     block:^(NSTimer * _Nonnull timer) {
                                                         doRequest();
                                                     }];
    }
}

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
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            if (settings.alertSetting == UNNotificationSettingEnabled) {
                [self enableRemoteNotificationFeatures];
                handler(YES);
            } else {
                [self disableRemoteNotificationFeatures];
                handler(NO);
            }
        }];
    } else {
        if ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications]) {
            [self enableRemoteNotificationFeatures];
            handler(YES);
        } else {
            [self disableRemoteNotificationFeatures];
            handler(NO);
        }
    }
}

#pragma mark - Private Methods

- (void)jumpByNotifacation:(NSDictionary *)remoteNotification {
    if (remoteNotification) {
        id info = remoteNotification[kNatificationKeyBangumiIdentifier];
        if (info && [info isKindOfClass:[NSNumber class]]) {
            self.jumpToEpisodeNotificationDestinationBangumiIdentifier = (NSNumber *)info;
            self.isJumpToEpisodeNotificationHandled = NO;
        } else {
            self.jumpToEpisodeNotificationDestinationBangumiIdentifier = nil;
            self.isJumpToEpisodeNotificationHandled = YES;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:JumpToEpisodeNotification object:self];
    }
}

- (void)enableRemoteNotificationFeatures {
    self.enable = YES;
}

- (void)disableRemoteNotificationFeatures {
    self.enable = NO;
}

@end
