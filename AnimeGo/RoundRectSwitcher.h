//
//  RoundRectSwitcher.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/14.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ReactiveObjC.h>

@class RoundRectSwitcher;

@interface RoundRectSwitcher : UIButton

@property (nonatomic, strong) NSString *titleOn;
@property (nonatomic, strong) NSString *titleOff;
@property (nonatomic, strong) UIImage *imageOn;
@property (nonatomic, strong) UIImage *imageOff;
@property (nonatomic, assign) BOOL status;
@property (nonatomic, readonly) RACSignal *touchSignal;

@end
