//
//  NSDate+Convert.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/3.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Convert)

+ (NSArray *)weekdayNameArray;
+ (NSDate *)dateToday;
+ (NSDate *)dateFromString:(NSString *)string;
+ (NSDate *)dateFromIndex:(NSInteger)index;
- (NSString *)toString;
- (NSString *)toShortString;
- (NSInteger)toWeekday;
- (NSInteger)toIndex;

@end
