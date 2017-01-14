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

@end

@implementation RoundRectSwitcher

#pragma mark - UIButton (super class)

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    
    self.layer.cornerRadius = 10;
    self.titleEdgeInsets = UIEdgeInsetsMake(0, LCPadding, 0, LCPadding);
    self.status = NO;
    return self;
}

- (CGSize)intrinsicContentSize {
    CGSize size = [super intrinsicContentSize];
    return CGSizeMake(size.width + 2 * LCPadding, size.height);
}

#pragma mark - Private Methods

- (void)p_updateUI {
    if (self.status) {
        if (self.imageOn) {
            self.layer.borderWidth = 0;
            self.backgroundColor = nil;
            [self setBackgroundImage:self.imageOn forState:UIControlStateNormal];
        } else {
            self.layer.borderWidth = 0;
            self.backgroundColor = [UIColor ag_pinkColor];
        }
        [self setTitle:self.titleOn forState:UIControlStateNormal];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        if (self.imageOn) {
            self.layer.borderWidth = 0;
            self.backgroundColor = nil;
            [self setBackgroundImage:self.imageOff forState:UIControlStateNormal];
        } else {
            self.layer.borderWidth = 1;
            self.layer.borderColor = [UIColor ag_pinkColor].CGColor;
            self.backgroundColor = [UIColor whiteColor];
        }
        [self setTitle:self.titleOff forState:UIControlStateNormal];
        [self setTitleColor:[UIColor ag_pinkColor] forState:UIControlStateNormal];
    }
}

#pragma mark - Public Methods

- (RACSignal *)touchSignal {
    return [[self rac_signalForControlEvents:UIControlEventTouchUpInside]
            doNext:^(__kindof UIControl * _Nullable x) {
                self.status = !self.status;
            }];
}

- (void)setStatus:(BOOL)status {
    _status = status;
    [self p_updateUI];
}

- (void)setTitleOn:(NSString *)titleOn {
    _titleOn = titleOn;
    [self p_updateUI];
}

- (void)setTitleOff:(NSString *)titleOff {
    _titleOff = titleOff;
    [self p_updateUI];
}

- (void)setImageOn:(UIImage *)imageOn {
    _imageOn = imageOn;
    [self p_updateUI];
}

- (void)setImageOff:(UIImage *)imageOff {
    _imageOff = imageOff;
    [self p_updateUI];
}

@end
