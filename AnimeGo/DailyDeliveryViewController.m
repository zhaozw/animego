//
//  DailyDeliveryViewController.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/25.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "DailyDeliveryViewController.h"
#import "MainViewController.h"
#import "VerticalTableView.h"
#import "BangumiTableViewCell.h"
#import "Bangumi+Create.h"
#import "Schedule+Create.h"
#import "NSDate+Convert.h"
#import "AppDelegate.h"

#define MAS_SHORTHAND
#import "Masonry.h"

static NSInteger kAutoRefreshTimeInterval = 30 * 60;
static NSInteger kMinErrorTryTimeInterval = 30;
static NSInteger kMinNormalFetchTimeInterval = 30 * 60;

@interface DailyDeliveryViewController ()

@property (strong, nonatomic) HorizontalTableView *horizontalTableView;
@property (strong, nonatomic) NSMutableDictionary *nextFetchTryTime;
@property (nonatomic) BOOL isFirstTimeAppear;

@end

@implementation DailyDeliveryViewController

#pragma mark - <HorizontalTableViewDelegate>

- (void)horizontalTableView:(HorizontalTableView *)sender scrollToIndex:(NSInteger)index {
    [self fetchCurrentIndexDataForce:NO];
}

#pragma mark - <HorizontalTableViewDataSource>

- (__kindof UIView *)horizontalTableView:(HorizontalTableView *)sender cellForIndex:(NSInteger)index {
    VerticalTableView *tableCell = nil;
    id newObject = [sender dequeueReusableCell];
    if (newObject && [newObject isKindOfClass:[VerticalTableView class]]) {
        tableCell = (VerticalTableView *)newObject;
        tableCell.dataSource = self;
        tableCell.delegate = self;

        
        [tableCell registerCellPrototypeClass:[BangumiTableViewCell class]];
        
        NSDate *date = [NSDate dateFromIndex:index];
        tableCell.date = date;

        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Schedule"];
        request.predicate = [NSPredicate predicateWithFormat:@"(releaseDate == %@) AND (display > 0)", date];
        NSSortDescriptor *isReleased = [NSSortDescriptor sortDescriptorWithKey:@"status" ascending:NO];
        NSSortDescriptor *prioritySort = [NSSortDescriptor sortDescriptorWithKey:@"bangumi.priority" ascending:NO];
        NSSortDescriptor *hotSort = [NSSortDescriptor sortDescriptorWithKey:@"bangumi.hot" ascending:NO];
        [request setSortDescriptors:@[isReleased, prioritySort, hotSort]];

        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        NSManagedObjectContext *context = appDelegate.mainMOC;
        [tableCell setRequest:request withManagedObjectContext:context];
    }
    return tableCell;
}

#pragma mark - <VerticalTableViewDataSource>

- (void)verticalTableView:(VerticalTableView *)sender
            configureCell:(__kindof UITableViewCell *)cell
                 forIndex:(NSInteger)index
        withFetchedResult:(id)object {
    
    if ([object isKindOfClass:[Schedule class]]) {
        Schedule *schedule = (Schedule *)object;
        if ([cell isKindOfClass:[BangumiTableViewCell class]]) {
            BangumiTableViewCell *bangumiCell = (BangumiTableViewCell *)cell;
            bangumiCell.schedule = schedule;
        }
    }
}

#pragma mark - <VerticalTableViewDelegate>

- (void)verticalTableView:(VerticalTableView *)sender
          touchRowAtIndex:(NSInteger)index
        withFetchedResult:(id)object {
    
    if ([object isKindOfClass:[Schedule class]]) {
        Bangumi *bangumi = ((Schedule *)object).bangumi;
        [self.parentViewController performSegueWithIdentifier:kSegueIdentifier sender:bangumi.identifier];
    }
}

#pragma mark - Life Cycle Mothods

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isFirstTimeAppear = YES;
    
    self.horizontalTableView = [[HorizontalTableView alloc] init];
    self.horizontalTableView.initIndex = [[NSDate dateToday] toIndex];
    [self.horizontalTableView registerClass:[VerticalTableView class]];
    self.horizontalTableView.delegate = self;
    self.horizontalTableView.dataSource = self;
    [self.view addSubview:self.horizontalTableView];
    
    [self.horizontalTableView makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_topLayoutGuide);
        make.bottom.equalTo(self.mas_bottomLayoutGuide);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.parentViewController.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
    if (!self.isFirstTimeAppear) {
        for (UIView *cell in self.horizontalTableView.displayCellArray) {
            if ([cell isKindOfClass:[VerticalTableView class]]) {
                VerticalTableView *tableCell = (VerticalTableView *)cell;
                [tableCell performFetch];
                [tableCell reloadData];
            }
        }
    }
    self.isFirstTimeAppear = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.parentViewController.navigationItem.rightBarButtonItem = nil;
}

#pragma mark - Protected Methods

- (NSTimeInterval)autoRefreshTimeInterval {
    return kAutoRefreshTimeInterval;
}

- (void)fetchRemoteData {
    [self fetchCurrentIndexDataForce:YES];
}

- (void)fetchCurrentIndexDataForce:(BOOL)force {
    NSInteger currentIndex = self.horizontalTableView.currentIndex;
    NSInteger week = currentIndex / 7;
    [self fetchRemoteDataForWeek:week force:force];
    [self fetchRemoteDataForWeek:week - 1 force:force];
    [self fetchRemoteDataForWeek:week + 1 force:force];
}

- (void)touchRefreshButton {
    self.horizontalTableView.currentIndex = [[NSDate dateToday] toIndex];
    [super touchRefreshButton];
}

- (void)fetchRemoteDataForWeek:(NSInteger)week
                         force:(BOOL)isForce {
    if (week < 0) return;
    
    if (!isForce) {
        NSDate *time = self.nextFetchTryTime[@(week)];
        if (time && [time timeIntervalSinceNow] > 0) return;
    }

    NSDate *now = [[NSDate alloc] init];
    BOOL isSent = [self fetchDailyDeliveryForWeek:week
                                          success:^{
                                              NSDate *next = [now dateByAddingTimeInterval:kMinNormalFetchTimeInterval];
                                              self.nextFetchTryTime[@(week)] = next;
                                          } connectionError:^(NSError *error) {
                                              NSDate *next = [now dateByAddingTimeInterval:kMinErrorTryTimeInterval];
                                              self.nextFetchTryTime[@(week)] = next;
                                          } serverError:^(NSInteger error) {
                                              NSDate *next = [now dateByAddingTimeInterval:kMinErrorTryTimeInterval];
                                              self.nextFetchTryTime[@(week)] = next;
                                          }];
    if (isSent) {
        NSDate *next = [now dateByAddingTimeInterval:kMinNormalFetchTimeInterval];
        self.nextFetchTryTime[@(week)] = next;
    } else {
        self.nextFetchTryTime[@(week)] = now;
    }
}

#pragma mark - Private Properties

- (NSMutableDictionary *)nextFetchTryTime {
    if (!_nextFetchTryTime) _nextFetchTryTime = [[NSMutableDictionary alloc] init];
    return _nextFetchTryTime;
}

@end
