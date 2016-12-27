//
//  IndicatorBarButton.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/30.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "IndicatorBarButton.h"
#import "LayoutConstant.h"

@interface IndicatorBarButton ()

@property (strong, nonatomic, readwrite) UIButton *button;
@property (strong, nonatomic) UIView *indicatorView;

@end

@implementation IndicatorBarButton

- (instancetype)initWithTitle:(NSString *)title indicatorColor:(UIColor *)color target:(id)target action:(SEL)action {
    self = [super init];
    if (self) {
        self.button = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.button setTitle:title forState:UIControlStateNormal];
        CGSize size = self.button.intrinsicContentSize;
        self.button.frame = CGRectMake(0, 0, size.width, size.height);
        [self.button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.button];
        
        self.indicatorView = [[UIView alloc] init];
        self.indicatorView.backgroundColor = color;
        self.indicatorView.frame = CGRectMake(0, size.height - LCSelectedIndicatorHeight,
                                              size.width, LCSelectedIndicatorHeight);
        [self addSubview:self.indicatorView];
        
        self.frame = CGRectMake(0, 0, size.width, size.height);
        self.indicator = NO;
    }
    return self;
}

- (BOOL)indicator {
    return !self.indicatorView.hidden;
}

- (void)setIndicator:(BOOL)indicator {
    self.indicatorView.hidden = !indicator;
}

@end
