//
//  RoundRectSwitcher.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/14.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RoundRectSwitcher;

@protocol RoundRectSwitcherDelegate <NSObject>

- (void)switcherView:(RoundRectSwitcher *)switcherView statusChanged:(BOOL)status;

@end

@interface RoundRectSwitcher : UIButton

@property (strong, nonatomic) NSString *titleOn;
@property (strong, nonatomic) NSString *titleOff;
@property (nonatomic) BOOL status;
@property (weak, nonatomic) id<RoundRectSwitcherDelegate> delegate;

@end
