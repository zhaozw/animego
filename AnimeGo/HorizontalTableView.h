//
//  HorizontalTableView.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/25.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HorizontalTableView;

@protocol HorizontalTableViewDataSource <NSObject>

- (__kindof UIView *)horizontalTableView:(HorizontalTableView *)sender cellForIndex:(NSInteger)index;

@end

@protocol HorizontalTableViewDelegate <NSObject>
@optional
- (void)horizontalTableView:(HorizontalTableView *)sender
              scrollToIndex:(NSInteger)index;

@end

@interface HorizontalTableView : UIView <UIScrollViewDelegate>

@property (weak, nonatomic) id<HorizontalTableViewDataSource> dataSource;
@property (weak, nonatomic) id<HorizontalTableViewDelegate> delegate;
@property (strong, readonly, nonatomic) NSMutableArray<__kindof UIView *> *displayCellArray;
@property (nonatomic) NSInteger initIndex;
@property (nonatomic) NSInteger currentIndex;

- (void)registerClass:(Class)cellClass;
- (__kindof UIView *)dequeueReusableCell;

@end
