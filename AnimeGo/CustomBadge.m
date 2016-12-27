//
//  CustomBadge.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/4.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "CustomBadge.h"
#import "LayoutConstant.h"
#import "UIColor+ExtraColor.h"

@interface CustomBadge ()

@property (nonatomic) CGRect rectBounds;

@end

@implementation CustomBadge

#pragma mark - Public Properties

- (void)setIsFavorite:(BOOL)isFavorite {
    if (_isFavorite == isFavorite) return;
    _isFavorite = isFavorite;
    [self setNeedsDisplay];
}

- (void)setEventCount:(NSInteger)eventCount {
    if (_eventCount == eventCount) return;
    _eventCount = eventCount;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    if (!self.isFavorite) return;
    
    UIUserInterfaceIdiom deviceType = [[UIDevice currentDevice] userInterfaceIdiom];
    CGFloat badgeHeight = (deviceType == UIUserInterfaceIdiomPad) ? LCCustomBadgeHeight : LCCustomBadgeHeightPhone;
    
    CGRect textRect = CGRectZero;
    CGFloat extraWidth = 0;
    NSAttributedString *cornerText;
    if (self.eventCount) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleCallout];
        font = [font fontWithSize:font.pointSize * (badgeHeight * LCCustomBadgeFontFactor)];
        
        NSDictionary *attributes = @{ NSFontAttributeName: font,
                                      NSForegroundColorAttributeName: [UIColor whiteColor],
                                      NSParagraphStyleAttributeName: paragraphStyle };
        
        NSString *string = self.eventCount < 100 ? [NSString stringWithFormat:@"%ld", (long)self.eventCount] : @"99+";
        cornerText = [[NSAttributedString alloc] initWithString:string
                                                     attributes:attributes];

        textRect.size = [cornerText size];
        NSInteger length = [cornerText length];
        CGFloat charWidth = [[NSAttributedString alloc] initWithString:@"0" attributes:attributes].size.width;
        extraWidth = (length - 1) * charWidth;
    }
    
    self.rectBounds = CGRectMake(0, 0,
                                 badgeHeight + extraWidth,
                                 badgeHeight);
    UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:self.rectBounds
                                                           cornerRadius:badgeHeight / 2];

    [[UIColor pinkColor] setFill];
    [roundedRect fill];
    
    if (self.eventCount) {
        textRect.origin = CGPointMake((self.rectBounds.size.width - textRect.size.width) / 2,
                                      (self.rectBounds.size.height - textRect.size.height) / 2);
        [cornerText drawInRect:textRect];
    }
    
    [self invalidateIntrinsicContentSize];
}

- (CGSize)intrinsicContentSize {
    UIUserInterfaceIdiom deviceType = [[UIDevice currentDevice] userInterfaceIdiom];
    CGFloat badgeHeight = (deviceType == UIUserInterfaceIdiomPad) ? LCCustomBadgeHeight : LCCustomBadgeHeightPhone;

    if (self.rectBounds.size.height < badgeHeight) return CGSizeMake(badgeHeight, badgeHeight);
    return self.rectBounds.size;
}

#pragma mark - Initialize

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = nil;
        self.opaque = NO;
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}

@end
