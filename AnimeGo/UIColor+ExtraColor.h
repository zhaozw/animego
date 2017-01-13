//
//  UIColor+ExtraColor.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/15.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (ExtraColor)

+ (UIColor *)ag_colorWith256Red:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue alpha:(CGFloat)alpha;
+ (UIColor *)ag_colorWith256Red:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue;

+ (UIColor *)ag_pinkColor;
+ (UIColor *)ag_translucentBlackColor;

@end
