//
//  VerticalTableView.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/24.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class VerticalTableView;

@protocol VerticalTableViewDataSource <NSObject>

- (void)verticalTableView:(VerticalTableView *)sender
            configureCell:(__kindof UITableViewCell *)cell
                 forIndex:(NSInteger)index
        withFetchedResult:(id)object;

@end

@protocol VerticalTableViewDelegate <NSObject>

@optional
- (void)verticalTableView:(VerticalTableView *)sender
          touchRowAtIndex:(NSInteger)index
        withFetchedResult:(id)object;

@end

@interface VerticalTableView : UIView <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSDate *date;

@property (nonatomic, weak) id<VerticalTableViewDelegate> delegate;
@property (nonatomic, weak) id<VerticalTableViewDataSource> dataSource;

- (void)setRequest:(NSFetchRequest *)request withManagedObjectContext:(NSManagedObjectContext *)context;
- (void)registerCellPrototypeClass:(Class)cellClass;
- (__kindof UIView *)dequeueReusableCellForIndex:(NSInteger)index;
- (void)performFetch;
- (void)reloadData;

@end
