//
//  HorizontalTableView.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/25.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "HorizontalTableView.h"
#import "LayoutConstant.h"

#define MAS_SHORTHAND
#import "Masonry.h"

static const NSInteger kTableCount = 1000;
static const NSInteger kCacheSize = 5;

@interface HorizontalTableView()

@property (strong, nonatomic) UIScrollView *scrollView;

@property (strong, nonatomic) NSMutableArray<__kindof UIView *> *reusableCellArray;
@property (strong, readwrite, nonatomic) NSMutableArray<__kindof UIView *> *displayCellArray;
@property (nonatomic) Class cellClass;

@property (nonatomic) CGSize tableSize;   // include padding
@property (nonatomic) NSInteger tableDisplayCount;

@property (nonatomic) NSInteger scrollingDirection;
@property (nonatomic) BOOL isScrolling;
@property (nonatomic) BOOL isInitialized;

@end

@implementation HorizontalTableView

@synthesize currentIndex = _currentIndex;

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

#pragma mark Initialize & UI Layout

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.scrollingDirection = 0;
        self.isInitialized = NO;
        self.isScrolling = NO;
        self.backgroundColor = [UIColor groupTableViewBackgroundColor];
        
        self.scrollView = [[UIScrollView alloc] init];
        self.scrollView.delegate = self;
        self.scrollView.scrollsToTop = NO;
        self.scrollView.showsVerticalScrollIndicator = NO;
        self.scrollView.showsHorizontalScrollIndicator = NO;
        [self addSubview:self.scrollView];
    }
    return self;
}

- (void)updateConstraints {
    if (![self.constraints count]) {
        [self.scrollView makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@(LCPadding));
            make.right.equalTo(@(-LCPadding));
            make.top.equalTo(@(LCPadding));
            make.bottom.equalTo(@(-LCPadding));
        }];
    }
    
    [super updateConstraints];
}

- (void)positionCell:(UIView *)cell {
    NSInteger index = cell.tag - 100;
    CGFloat offsetX = index * self.tableSize.width;
    cell.frame = CGRectMake(offsetX + LCPadding / 2, 0, self.tableSize.width - LCPadding, self.tableSize.height);
//    [cell remakeConstraints:^(MASConstraintMaker *make) {
//        make.top.equalTo(@0);
//        make.left.equalTo(@(offsetX + LCPadding / 2));
//        make.width.equalTo(@(self.tableSize.width - LCPadding));
//        make.height.equalTo(@(self.tableSize.height));
//    }];
}

#pragma mark UI Event

- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize scrollViewSize = self.scrollView.frame.size;
    
    UIUserInterfaceIdiom deviceType = [[UIDevice currentDevice] userInterfaceIdiom];
    CGFloat minTableCellWidth = (deviceType == UIUserInterfaceIdiomPad) ? LCMinTableCellWidth : LCMinTableCellWidthPhone;
    self.tableDisplayCount = scrollViewSize.width / minTableCellWidth;
    
    if (self.tableDisplayCount == 0) self.tableDisplayCount = 1;
    CGSize tableSize = CGSizeMake(scrollViewSize.width / self.tableDisplayCount, scrollViewSize.height);
    BOOL tableSizeChanged = tableSize.width != self.tableSize.width || tableSize.height != self.tableSize.height;
    self.tableSize = tableSize;
    self.scrollView.contentSize = CGSizeMake(tableSize.width * kTableCount, tableSize.height);
    
    if (tableSizeChanged) {
        for (UIView *cellIter in self.displayCellArray) {
            [self positionCell:cellIter];
            [cellIter setNeedsUpdateConstraints];
        }
    }
    
    if (!self.isInitialized) {
        [self setCurrentIndex:self.initIndex correctOffset:YES];
        self.isInitialized = YES;
    } else {
        [self setCurrentIndex:self.currentIndex correctOffset:YES];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    static NSInteger oldOffset = 0;
    if (self.scrollView.contentOffset.x > oldOffset) {
        self.scrollingDirection = 1;
    } else if (self.scrollView.contentOffset.x < oldOffset) {
        self.scrollingDirection = -1;
    } else {
        self.scrollingDirection = 0;
    }
    oldOffset = self.scrollView.contentOffset.x;
    if (!self.isInitialized) return;
    NSInteger index = [self indexForOffsetX:scrollView.contentOffset.x] + (self.tableDisplayCount - 1) / 2;
    if (index != self.currentIndex) {
        [self prepareForCellAtIndex:index];
        [self setCurrentIndex:index correctOffset:NO];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) [self setCurrentIndex:self.currentIndex correctOffset:YES];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    [self setCurrentIndex:(self.currentIndex + self.scrollingDirection) correctOffset:YES];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    self.isScrolling = NO;
}

#pragma mark Private Property

- (NSMutableArray *)displayCellArray {
    if (!_displayCellArray) _displayCellArray = [[NSMutableArray alloc] init];
    return _displayCellArray;
}

- (NSMutableArray *)reusableCellArray {
    if (!_reusableCellArray) _reusableCellArray = [[NSMutableArray alloc] init];
    return _reusableCellArray;
}

#pragma mark Public Property

- (NSInteger)currentIndex {
    return self.isInitialized ? _currentIndex : self.initIndex;
}

- (void)setCurrentIndex:(NSInteger)currentIndex {
    [self setCurrentIndex:currentIndex correctOffset:YES];
}

- (void)setCurrentIndex:(NSInteger)currentIndex correctOffset:(BOOL)correctOffset {
    NSInteger minIndex = (self.tableDisplayCount - 1) / 2;
    NSInteger maxIndex = kTableCount - self.tableDisplayCount / 2 - 1;
    if (currentIndex > maxIndex) currentIndex = maxIndex;
    if (currentIndex < minIndex) currentIndex = minIndex;
    BOOL isChanged = (_currentIndex != currentIndex);
    _currentIndex = currentIndex;

    if (isChanged && !self.isScrolling) {
        [self.delegate horizontalTableView:self scrollToIndex:currentIndex];
    }
    
    CGFloat newOffset = self.tableSize.width * (currentIndex - (self.tableDisplayCount - 1) / 2);
    [self prepareForCellAtIndex:currentIndex];
    if (correctOffset) {
        [self.scrollView setContentOffset:CGPointMake(newOffset, 0) animated:YES];
        self.isScrolling = YES;
    }
}

#pragma mark Private Methods

- (NSInteger)indexForOffsetX:(CGFloat)offsetX {
    return (offsetX + self.tableSize.width / 2) / self.tableSize.width;
}

- (NSInteger)indexForCell:(__kindof UIView *)cell {
    return [self indexForOffsetX:cell.frame.origin.x];
}

- (void)prepareForCellAtIndex:(NSInteger)index {
    NSInteger indexBegin = index - (self.tableDisplayCount - 1) / 2 - kCacheSize;
    NSInteger indexEnd = index + self.tableDisplayCount / 2 + 1 + kCacheSize;
    if (indexBegin < 0) indexBegin = 0;
    if (indexEnd > kTableCount) indexEnd = kTableCount;
    
    int i = 0;
    while (i < [self.displayCellArray count]) {
        UIView *cell = self.displayCellArray[i];
        NSInteger iterIndex = [self indexForCell:cell];
        if (iterIndex < indexBegin - 1 || iterIndex > indexEnd + 1) {
            [self.reusableCellArray addObject:cell];
            [self.displayCellArray removeObject:cell];
        } else {
            ++i;
        }
    }
    
    for (NSInteger iterIndex = indexBegin; iterIndex <= indexEnd; ++iterIndex) {
        UIView *cell = nil;
        for (UIView *cellIter in self.displayCellArray) {
            if (cellIter.tag - 100 == iterIndex) {
                cell = cellIter;
                break;
            }
        }
        if (!cell) {
            cell = [self.dataSource horizontalTableView:self cellForIndex:iterIndex];
            cell.tag = 100 + iterIndex;
            [self.displayCellArray addObject:cell];
            [self.scrollView addSubview:cell];
        }
        [self positionCell:cell];
    }
}

#pragma mark Public Methods

- (void)registerClass:(Class)cellClass {
    self.cellClass = cellClass;
}

- (__kindof UIView *)dequeueReusableCell {
    if ([self.reusableCellArray count]) {
        UIView *cell = [self.reusableCellArray firstObject];
        [self.reusableCellArray removeObject:cell];
        return cell;
    }
    CGRect rect = CGRectMake(0, 0, self.tableSize.width - LCPadding, self.tableSize.height);
    UIView *cell = [[self.cellClass alloc] initWithFrame:rect];
    return cell;
}

@end
