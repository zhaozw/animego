//
//  NSString+Append.m
//  AnimeGo
//
//  Created by Chaoran Li on 2017/1/9.
//  Copyright © 2017年 Chaoran Li. All rights reserved.
//

#import "NSString+Append.h"

@implementation NSString (Append)

- (NSString *)stringByAppendingStringWithComma:(NSString *)aString {
    if ([self isEqualToString:@""]) return aString;
    if ([aString isEqualToString:@""]) return self;
    return [NSString stringWithFormat:@"%@, %@", self, aString];
}

@end
