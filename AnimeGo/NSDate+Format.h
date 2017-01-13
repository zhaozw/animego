//
//  NSDate+Format.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/3.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Format)

+ (NSArray *)ag_weekdayNameArray;
+ (NSDate *)ag_dateToday;
+ (NSDate *)ag_dateFromString:(NSString *)string;
+ (NSDate *)ag_dateFromIndex:(NSInteger)index;
- (NSString *)ag_toString;
- (NSString *)ag_toShortString;
- (NSInteger)ag_toWeekday;
- (NSInteger)ag_toIndex;

@end
