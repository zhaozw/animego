//
//  VerticalTableView.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/24.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "VerticalTableView.h"
#import "LayoutConstant.h"
#import "NSDate+Convert.h"
#import "UIColor+ExtraColor.h"
#import "LayoutConstant.h"

#define MAS_SHORTHAND
#import "Masonry.h"

static NSString * const kIdentifier = @"Cell";

@interface VerticalTableView()

@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) UILabel *weekdayLabel;
@property (strong, nonatomic) UILabel *dateLabel;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) BOOL didConstraintsSetup;

@end

@implementation VerticalTableView

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

#pragma Initialize (UI Layout)

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.didConstraintsSetup = NO;
        UIUserInterfaceIdiom deviceType = [[UIDevice currentDevice] userInterfaceIdiom];
        
        self.headerView = [[UIView alloc] init];
        self.headerView.backgroundColor = [UIColor pinkColor];
        [self addSubview:self.headerView];
        
        UIFont *weekdayLabelFont = (deviceType == UIUserInterfaceIdiomPad)
            ? [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1]
            : [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
        self.weekdayLabel = [[UILabel alloc] init];
        self.weekdayLabel.font = weekdayLabelFont;
        self.weekdayLabel.textColor = [UIColor whiteColor];
        [self.headerView addSubview:self.weekdayLabel];
        
        self.dateLabel = [[UILabel alloc] init];
        self.dateLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        self.dateLabel.textColor = [UIColor whiteColor];
        [self.headerView addSubview:self.dateLabel];
        
        self.tableView = [[UITableView alloc] init];
//        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
//        self.tableView.separatorColor = [UIColor grayColor];
//        self.tableView.separatorInset = UIEdgeInsetsMake(0, 10, 0, 10);
//        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
//        UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
//        self.tableView.separatorEffect = vibrancyEffect;

        CGFloat tableCellAspectRatio = (deviceType == UIUserInterfaceIdiomPad)
            ? LCTableCellAspectRatio
            : LCTableCellAspectRatioPhone;
        self.tableView.estimatedRowHeight = frame.size.width * tableCellAspectRatio;
        
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        self.tableView.bounces = NO;
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        [self addSubview:self.tableView];
    }
    return self;
}

- (void)updateConstraints {
    if (!self.didConstraintsSetup) {
        self.didConstraintsSetup = YES;
        
        UIUserInterfaceIdiom deviceType = [[UIDevice currentDevice] userInterfaceIdiom];
        CGFloat headerHeight = (deviceType == UIUserInterfaceIdiomPad) ? LCHeaderHeight : LCHeaderHeightPhone;
        [self.headerView makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self);
            make.left.equalTo(self);
            make.right.equalTo(self);
            make.height.equalTo(@(headerHeight));
        }];
        
        [self.weekdayLabel makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@(LCPadding / 2));
            make.bottom.equalTo(@(-LCPadding / 2));
        }];
        
        [self.dateLabel makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@(-LCPadding / 2));
            make.bottom.equalTo(@(-LCPadding / 2));
        }];
        
        [self.tableView makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.headerView.bottom);
            make.left.equalTo(self);
            make.right.equalTo(self);
            make.bottom.equalTo(self);
        }];
    }
    [super updateConstraints];
}

#pragma mark - <UITableViewDataSource>

- (void)configureCell:(id)cell atIndexPath:(NSIndexPath*)indexPath {    
    id object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    [self.dataSource verticalTableView:self
                         configureCell:cell
                              forIndex:indexPath.row
                     withFetchedResult:object];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id cell = [tableView dequeueReusableCellWithIdentifier:kIdentifier];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIUserInterfaceIdiom deviceType = [[UIDevice currentDevice] userInterfaceIdiom];
    if (deviceType == UIUserInterfaceIdiomPad) {
        return tableView.bounds.size.width * LCTableCellAspectRatio;
    } else {
        return tableView.bounds.size.width * LCTableCellAspectRatioPhone;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

#pragma mark - <UITableViewDelegate>

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self.delegate verticalTableView:self
                     touchRowAtIndex:indexPath.row
                   withFetchedResult:object];
    return nil;
}

#pragma mark - <NSFetchedResultsControllerDelegate>

//- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
//    [[self tableView] beginUpdates];
//}
//
//- (void)controller:(NSFetchedResultsController *)controller
//  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
//           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
//    
//    switch(type) {
//        case NSFetchedResultsChangeInsert:
//            [[self tableView] insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//        case NSFetchedResultsChangeDelete:
//            [[self tableView] deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//        case NSFetchedResultsChangeMove:
//        case NSFetchedResultsChangeUpdate:
//            break;
//    }
//}
//
//- (void)controller:(NSFetchedResultsController *)controller
//   didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath
//     forChangeType:(NSFetchedResultsChangeType)type
//      newIndexPath:(NSIndexPath *)newIndexPath {
//    
//    switch(type) {
//        case NSFetchedResultsChangeInsert:
//            [[self tableView] insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//        case NSFetchedResultsChangeDelete:
//            [[self tableView] deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//        case NSFetchedResultsChangeUpdate:
//            [self configureCell:[[self tableView] cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
//            break;
//        case NSFetchedResultsChangeMove:
//            [[self tableView] deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//            [[self tableView] insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//    }
//}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView reloadData];
//    [[self tableView] endUpdates];
}

#pragma mark Public Property

- (void)setDate:(NSDate *)date {
    _date = date;
    NSInteger weekday = [date toWeekday];
    self.weekdayLabel.text = [NSDate weekdayNameArray][weekday];
    UIColor *headerColor = nil;
    switch (weekday) {
        case 1:
            headerColor = [UIColor colorWith256Red:255 green:0 blue:0];
            break;
        case 2:
            headerColor = [UIColor colorWith256Red:255 green:77 blue:0];
            break;
        case 3:
            headerColor = [UIColor colorWith256Red:255 green:152 blue:0];
            break;
        case 4:
            headerColor = [UIColor colorWith256Red:157 green:233 blue:0];
            break;
        case 5:
            headerColor = [UIColor colorWith256Red:0 green:199 blue:30];
            break;
        case 6:
            headerColor = [UIColor colorWith256Red:0 green:131 blue:0];
            break;
        case 7:
            headerColor = [UIColor colorWith256Red:0 green:77 blue:169];
            break;
        default:
            ;
    }
    self.headerView.backgroundColor = headerColor;
    NSString *shortDate = [date toShortString];
    if ([shortDate isEqualToString:[[NSDate dateToday] toShortString]]) {
        self.dateLabel.text = [NSString stringWithFormat:@"%@ (今天)", shortDate];
    } else {
        self.dateLabel.text = shortDate;
    }
    
}

- (NSFetchRequest *)request {
    return self.fetchedResultsController.fetchRequest;
}

- (void)setRequest:(NSFetchRequest *)request withManagedObjectContext:(NSManagedObjectContext *)context {
    if (!self.fetchedResultsController) {
//        NSString *cacheName = [self.date toString];
        NSString *cacheName = nil;
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                            managedObjectContext:context
                                                                              sectionNameKeyPath:nil
                                                                                       cacheName:cacheName];
        
        self.fetchedResultsController.delegate = self;
        [self.fetchedResultsController performFetch:nil];
    } else {
        self.fetchedResultsController.fetchRequest.predicate = request.predicate;
        self.fetchedResultsController.fetchRequest.fetchLimit = request.fetchLimit;
        self.fetchedResultsController.fetchRequest.fetchBatchSize = request.fetchBatchSize;
        self.fetchedResultsController.fetchRequest.fetchOffset = request.fetchOffset;
        self.fetchedResultsController.fetchRequest.sortDescriptors = request.sortDescriptors;
        [self.fetchedResultsController performFetch:nil];
        [self.tableView reloadData];
    }
}

- (void)performFetch {
    [self.fetchedResultsController performFetch:nil];
}

#pragma mark Public Methods

- (void)registerCellPrototypeClass:(Class)cellClass {
    [self.tableView registerClass:cellClass forCellReuseIdentifier:kIdentifier];
}

- (__kindof UITableViewCell *)dequeueReusableCellForIndex:(NSInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    return [self.tableView dequeueReusableCellWithIdentifier:kIdentifier forIndexPath:indexPath];
}

- (void)reloadData {
    [self.tableView reloadData];
}

@end
