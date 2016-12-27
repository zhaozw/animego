//
//  NSDate+Convert.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/3.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "NSDate+Convert.h"

static NSString * const kOrginDate = @"2016-10-30";
static const NSInteger kSecondsFromGMT = 8 * 60 * 60;
static const NSInteger kDayTimeInterval = 24 * 60 * 60;

@implementation NSDate (Convert)

+ (NSArray *)weekdayNameArray {
    return @[@"", @"星期日", @"星期一", @"星期二", @"星期三", @"星期四", @"星期五", @"星期六"];
}

+ (NSDate *)dateToday {
    return [NSDate dateFromString:[[[NSDate alloc] init] toString]];
}

+ (NSDate *)dateFromString:(NSString *)string {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:kSecondsFromGMT];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    return [formatter dateFromString:string];
}

+ (NSDate *)dateFromIndex:(NSInteger)index {
    return [[NSDate dateFromString:kOrginDate] dateByAddingTimeInterval:kDayTimeInterval * index];
}

- (NSString *)toString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:kSecondsFromGMT];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    return [formatter stringFromDate:self];
}

- (NSString *)toShortString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:kSecondsFromGMT];
    [formatter setDateFormat:@"MM-dd"];
    return [formatter stringFromDate:self];
}

- (NSInteger)toWeekday {
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:kSecondsFromGMT];
    return [calendar component:NSCalendarUnitWeekday fromDate:self];
}

- (NSInteger)toIndex {
    double interval = [self timeIntervalSinceDate:[NSDate dateFromString:kOrginDate]];
    return floor(interval / kDayTimeInterval + 0.5);
}

@end
