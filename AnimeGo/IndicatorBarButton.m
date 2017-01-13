//
//  IndicatorBarButton.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/30.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "IndicatorBarButton.h"

#import <ReactiveObjC.h>
#import "LayoutConstant.h"

@interface IndicatorBarButton ()

@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) UIView *indicatorView;

@end

@implementation IndicatorBarButton

#pragma mark - Public Methods

- (instancetype)initWithTitle:(NSString *)title color:(UIColor *)color {
    self = [super init];
    if (!self) return nil;

    self.button = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.button setTitle:title forState:UIControlStateNormal];
    CGSize size = self.button.intrinsicContentSize;
    self.button.frame = CGRectMake(0, 0, size.width, size.height);
    [self addSubview:self.button];
    
    self.indicatorView = [[UIView alloc] init];
    self.indicatorView.backgroundColor = color;
    self.indicatorView.frame = CGRectMake(0, size.height - LCSelectedIndicatorHeight,
                                          size.width, LCSelectedIndicatorHeight);
    [self addSubview:self.indicatorView];
    
    self.frame = CGRectMake(0, 0, size.width, size.height);
    
    RAC(self, indicatorView.hidden) = [RACObserve(self, indicator) map:^id _Nullable(NSNumber *indicator) {
        return @(!(indicator.boolValue));
    }];
    
    self.indicator = NO;
    return self;
}

- (RACSignal *)touchSignal {
    return [self.button rac_signalForControlEvents:UIControlEventTouchUpInside];
}

@end
