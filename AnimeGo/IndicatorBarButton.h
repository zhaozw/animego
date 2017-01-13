//
//  IndicatorBarButton.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/30.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ReactiveObjC.h>

@interface IndicatorBarButton : UIView

@property (nonatomic, assign) BOOL indicator;
@property (nonatomic, readonly) RACSignal *touchSignal;

- (instancetype)initWithTitle:(NSString *)title color:(UIColor *)color;

@end
