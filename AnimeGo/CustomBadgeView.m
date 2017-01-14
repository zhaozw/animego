//
//  CustomBadgeView.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/4.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "CustomBadgeView.h"

#import "LayoutConstant.h"
#import "UIColor+ExtraColor.h"

@interface CustomBadgeView ()

@property (nonatomic, assign) CGRect rectBounds;

@end

@implementation CustomBadgeView

#pragma mark - UIView (super class)

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.backgroundColor = nil;
    self.opaque = NO;
    self.contentMode = UIViewContentModeRedraw;
    
    return self;
}

- (void)drawRect:(CGRect)rect {
    if (!self.favorite) return;
    
    UIUserInterfaceIdiom deviceType = [[UIDevice currentDevice] userInterfaceIdiom];
    CGFloat badgeHeight = (deviceType == UIUserInterfaceIdiomPad) ? LCCustomBadgeHeight : LCCustomBadgeHeightPhone;
    
    CGRect textRect = CGRectZero;
    CGFloat extraWidth = 0;
    NSAttributedString *cornerText;
    if (self.eventCount) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
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
    
    [[UIColor ag_pinkColor] setFill];
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

#pragma mark - Public Methods

- (void)setEventCount:(NSInteger)eventCount {
    if (_eventCount == eventCount) return;
    _eventCount = eventCount;
    [self setNeedsDisplay];
}

- (void)setFavorite:(BOOL)favorite {
    if (_favorite == favorite) return;
    _favorite = favorite;
    [self setNeedsDisplay];
}

@end
