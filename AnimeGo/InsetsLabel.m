//
//  InsetsLabel.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/15.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "InsetsLabel.h"

@implementation InsetsLabel

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.insets = UIEdgeInsetsMake(0, 0, 0, 0);
    }
    return self;
}

- (void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.insets)];
}

- (void)setInsets:(UIEdgeInsets)insets {
    _insets = insets;
    [self setNeedsDisplay];
}

- (CGSize)intrinsicContentSize {
    CGSize size = [super intrinsicContentSize];
    size.width += self.insets.left + self.insets.right;
    size.height += self.insets.top + self.insets.bottom;
    return size;
}

@end
