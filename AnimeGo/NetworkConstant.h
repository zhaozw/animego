//
//  NetworkConstant.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/27.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#ifndef NetworkConstant_h
#define NetworkConstant_h

typedef NS_ENUM(NSInteger, AGError) {
    AGErrorOk                   = 0,
    AGErrorBadCommand           = 1,
    AGErrorIllegalArgument      = 2,
    AGErrorRecordNotFound       = 3,
    AGErrorRecordExisted        = 4,
    AGErrorWrongPassword        = 5,
    AGErrorNotAllowed           = 6,
    AGErrorDatabaseError        = 7,
    AGErrorUnknownError         = 8
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

extern NSString * const ContentNeedUpdateNofification;

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
