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

@property (strong, nonatomic) NSDate *date;

@property (weak, nonatomic) id<VerticalTableViewDelegate> delegate;
@property (weak, nonatomic) id<VerticalTableViewDataSource> dataSource;

- (void)setRequest:(NSFetchRequest *)request withManagedObjectContext:(NSManagedObjectContext *)context;
- (void)registerCellPrototypeClass:(Class)cellClass;
- (__kindof UIView *)dequeueReusableCellForIndex:(NSInteger)index;
- (void)performFetch;
- (void)reloadData;

@end
