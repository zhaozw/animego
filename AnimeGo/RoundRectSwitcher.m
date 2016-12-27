//
//  RoundRectSwitcher.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/14.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "RoundRectSwitcher.h"
#import "LayoutConstant.h"
#import "UIColor+ExtraColor.h"

@interface RoundRectSwitcher ()

@property (nonatomic, nonatomic) SEL eventAction;
@property (weak, nonatomic) id eventTarget;

@end

@implementation RoundRectSwitcher

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.titleEdgeInsets = UIEdgeInsetsMake(0, LCPadding, 0, LCPadding);
        self.layer.cornerRadius = 10;
        self.status = NO;
        [self addTarget:self action:@selector(touchEvent) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    CGSize size = [super intrinsicContentSize];
    return CGSizeMake(size.width + 2 * LCPadding, size.height);
}

- (void)updateUI {
    if (self.status) {
        self.layer.borderWidth = 0;
        self.backgroundColor = [UIColor pinkColor];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self setTitle:self.titleOn forState:UIControlStateNormal];
    } else {
        self.layer.borderWidth = 1;
        self.layer.borderColor = [UIColor pinkColor].CGColor;
        self.backgroundColor = [UIColor whiteColor];
        [self setTitleColor:[UIColor pinkColor] forState:UIControlStateNormal];
        [self setTitle:self.titleOff forState:UIControlStateNormal];
    }
}

- (void)setStatus:(BOOL)status {
    _status = status;
    [self updateUI];
}

- (void)setTitleOn:(NSString *)titleOn {
    _titleOn = titleOn;
    [self updateUI];
}

- (void)setTitleOff:(NSString *)titleOff {
    _titleOff = titleOff;
    [self updateUI];
}

- (void)touchEvent {
    self.status = !self.status;
    [self.delegate switcherView:self statusChanged:self.status];
}

@end
