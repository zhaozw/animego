//
//  IndicatorBarButton.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/30.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IndicatorBarButton : UIView

@property (strong, readonly, nonatomic) UIButton *button;
@property (nonatomic) BOOL indicator;

- (instancetype)initWithTitle:(NSString *)title indicatorColor:(UIColor *)color target:(id)target action:(SEL)action;

@end
