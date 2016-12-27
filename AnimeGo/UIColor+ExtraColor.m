//
//  UIColor+ExtraColor.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/15.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "UIColor+ExtraColor.h"

@implementation UIColor (ExtraColor)

+ (UIColor *)colorWith256Red:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue {
    return [UIColor colorWithRed:(CGFloat)red/255 green:(CGFloat)green/255 blue:(CGFloat)blue/255 alpha:1.0];
}

+ (UIColor *)pinkColor {
    return [UIColor colorWith256Red:255 green:51 blue:133];
}

+ (UIColor *)translucentBlackColor {
    return [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
}

@end
