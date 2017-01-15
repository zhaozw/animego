//
//  UIColor+ExtraColor.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/15.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "UIColor+ExtraColor.h"

@implementation UIColor (ExtraColor)

+ (UIColor *)ag_colorWith256Red:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue alpha:(CGFloat)alpha {
    return [UIColor colorWithRed:(CGFloat)red/255.0 green:(CGFloat)green/255.0 blue:(CGFloat)blue/255.0 alpha:alpha];
}

+ (UIColor *)ag_colorWith256Red:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue {
    return [UIColor ag_colorWith256Red:red green:green blue:blue alpha:1.0];
}

+ (UIColor *)ag_pinkColor {
    return [UIColor ag_colorWith256Red:255 green:51 blue:133];
}

+ (UIColor *)ag_translucentBlackColor {
    return [UIColor ag_colorWith256Red:0 green:0 blue:0 alpha:0.5];
}

@end
