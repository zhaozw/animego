//
//  NSDate+Format.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/3.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "NSDate+Format.h"

static NSString * const kOrginDate = @"2016-10-30";
static const NSInteger kSecondsFromGMT = 8 * 60 * 60;
static const NSInteger kDayTimeInterval = 24 * 60 * 60;

@implementation NSDate (Format)

+ (NSArray *)ag_weekdayNameArray {
    return @[@"", @"星期日", @"星期一", @"星期二", @"星期三", @"星期四", @"星期五", @"星期六"];
}

+ (NSDate *)ag_dateToday {
    return [NSDate ag_dateFromString:[[[NSDate alloc] init] ag_toString]];
}

+ (NSDate *)ag_dateFromString:(NSString *)string {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:kSecondsFromGMT];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    return [formatter dateFromString:string];
}

+ (NSDate *)ag_dateFromIndex:(NSInteger)index {
    return [[NSDate ag_dateFromString:kOrginDate] dateByAddingTimeInterval:kDayTimeInterval * index];
}

- (NSString *)ag_toString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:kSecondsFromGMT];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    return [formatter stringFromDate:self];
}

- (NSString *)ag_toShortString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:kSecondsFromGMT];
    [formatter setDateFormat:@"MM-dd"];
    return [formatter stringFromDate:self];
}

- (NSInteger)ag_toWeekday {
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:kSecondsFromGMT];
    return [calendar component:NSCalendarUnitWeekday fromDate:self];
}

- (NSInteger)ag_toIndex {
    double interval = [self timeIntervalSinceDate:[NSDate ag_dateFromString:kOrginDate]];
    return floor(interval / kDayTimeInterval + 0.5);
}

@end
