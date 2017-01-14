//
//  InsetsLabel.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/15.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "InsetsLabel.h"

@implementation InsetsLabel

#pragma mark - UILabel (super class)

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    
    self.insets = UIEdgeInsetsMake(0, 0, 0, 0);
    return self;
}

- (void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.insets)];
}

- (CGSize)intrinsicContentSize {
    CGSize size = [super intrinsicContentSize];
    size.width += self.insets.left + self.insets.right;
    size.height += self.insets.top + self.insets.bottom;
    return size;
}

#pragma mark - Public Methods

- (void)setInsets:(UIEdgeInsets)insets {
    _insets = insets;
    [self setNeedsDisplay];
}

@end
