//
//  NetworkConstant.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/27.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef NetworkConstant_h
#define NetworkConstant_h

typedef NS_ENUM(NSInteger, AGErrorCode) {
    // Server error
    AGErrorServerOk                   = 0,
    AGErrorServerBadCommand           = 1,
    AGErrorServerIllegalArgument      = 2,
    AGErrorServerRecordNotFound       = 3,
    AGErrorServerRecordExisted        = 4,
    AGErrorServerWrongPassword        = 5,
    AGErrorServerNotAllowed           = 6,
    AGErrorServerDatabaseError        = 7,
    AGErrorServerUnknownError         = 8,
    
    // Client error
    AGErrorClientDuplicateRequest     = 101,
    AGErrorClientNetworkUnavailable   = 102,
    AGErrorClientNotRegistered        = 103
};

typedef NS_ENUM(NSInteger, AGScheduleStatus) {
    AGScheduleStatusNotReleased = 0,
    AGScheduleStatusReleased    = 1,
    AGScheduleStatusCanceled    = 2
};

typedef NS_ENUM(NSInteger, AGBangumiStatus) {
    AGBangumiStatusNotReleased  = 0,
    AGBangumiStatusReleased     = 1,
    AGBangumiStatusOver         = 2,
};

extern NSString * const AGErrorDomain;

extern NSString * const AGBangumiKeyId;
extern NSString * const AGBangumiKeyTitle;
extern NSString * const AGBangumiKeyHot;
extern NSString * const AGBangumiKeyCoverImageURL;
extern NSString * const AGBangumiKeyIsFavorite;
extern NSString * const AGBangumiKeyReleaseWeekdays;
extern NSString * const AGBangumiKeyTotalEpisodes;
extern NSString * const AGBangumiKeyFirstReleasedEpisode;
extern NSString * const AGBangumiKeyLastReleasedEpisode;
extern NSString * const AGBangumiKeyLastWatchedEpisode;
extern NSString * const AGBangumiKeyStatus;
extern NSString * const AGBangumiKeyLargeImageURL;
extern NSString * const AGBangumiKeyStuff;
extern NSString * const AGBangumiKeyCharacterVoice;
extern NSString * const AGBangumiKeySynopsis;
extern NSString * const AGBangumiKeyDeleted;

extern NSString * const AGScheduleKeyId;
extern NSString * const AGScheduleKeyTitle;
extern NSString * const AGScheduleKeyDisplay;
extern NSString * const AGScheduleKeyReleaseDate;
extern NSString * const AGScheduleKeyStatus;
extern NSString * const AGScheduleKeyEpisodeNumber;
extern NSString * const AGScheduleKeyBangumi;
extern NSString * const AGScheduleKeyDeleted;
extern NSString * const AGScheduleKeyWebURL;
extern NSString * const AGScheduleKeyPhoneAppURL;
extern NSString * const AGScheduleKeyPadAppURL;
extern NSString * const AGScheduleKeyAppInstallURL;

extern NSString * const AGAppInstallURLKeyName;
extern NSString * const AGAppInstallURLKeyPhoneInstallURL;
extern NSString * const AGAppInstallURLKeyPadInstallURL;

#endif /* NetworkConstant_h */
