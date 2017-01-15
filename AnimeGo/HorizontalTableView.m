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

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) NSMutableArray<__kindof UIView *> *reusableCellArray;
@property (nonatomic, strong, readwrite) NSMutableArray<__kindof UIView *> *displayCellArray;
@property (nonatomic, assign) Class cellClass;

@property (nonatomic, assign) CGSize tableSize;   // include padding
@property (nonatomic, assign) NSInteger tableDisplayCount;

@property (nonatomic, assign) NSInteger scrollingDirection;
@property (nonatomic, assign) BOOL isScrolling;
@property (nonatomic, assign) BOOL isInitialized;

@end

@implementation HorizontalTableView

@synthesize currentIndex = _currentIndex;

#pragma mark - UIView (super class)

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    
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
            [self p_positionCell:cellIter];
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

#pragma mark - <UIScrollViewDelegate>

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
    NSInteger index = [self p_indexForOffsetX:scrollView.contentOffset.x] + (self.tableDisplayCount - 1) / 2;
    if (index != self.currentIndex) {
        [self p_prepareForCellAtIndex:index];
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

#pragma mark - Private Methods

- (NSMutableArray *)displayCellArray {
    if (!_displayCellArray) _displayCellArray = [[NSMutableArray alloc] init];
    return _displayCellArray;
}

- (NSMutableArray *)reusableCellArray {
    if (!_reusableCellArray) _reusableCellArray = [[NSMutableArray alloc] init];
    return _reusableCellArray;
}

- (NSInteger)p_indexForOffsetX:(CGFloat)offsetX {
    return (offsetX + self.tableSize.width / 2) / self.tableSize.width;
}

- (NSInteger)p_indexForCell:(__kindof UIView *)cell {
    return [self p_indexForOffsetX:cell.frame.origin.x];
}

- (void)p_prepareForCellAtIndex:(NSInteger)index {
    NSInteger indexBegin = index - (self.tableDisplayCount - 1) / 2 - kCacheSize;
    NSInteger indexEnd = index + self.tableDisplayCount / 2 + 1 + kCacheSize;
    if (indexBegin < 0) indexBegin = 0;
    if (indexEnd > kTableCount) indexEnd = kTableCount;
    
    int i = 0;
    while (i < [self.displayCellArray count]) {
        UIView *cell = self.displayCellArray[i];
        NSInteger iterIndex = [self p_indexForCell:cell];
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
        [self p_positionCell:cell];
    }
}

- (void)p_positionCell:(UIView *)cell {
    NSInteger index = cell.tag - 100;
    CGFloat offsetX = index * self.tableSize.width;
    cell.frame = CGRectMake(offsetX + LCPadding / 2, 0, self.tableSize.width - LCPadding, self.tableSize.height);
}

#pragma mark - Public Methods

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
    [self p_prepareForCellAtIndex:currentIndex];
    if (correctOffset) {
        [self.scrollView setContentOffset:CGPointMake(newOffset, 0) animated:YES];
        self.isScrolling = YES;
    }
}

- (__kindof UIView *)cellForPoint:(CGPoint)point {
    CGPoint scrollViewLocation = [self.scrollView convertPoint:point fromView:self];
    NSInteger index = scrollViewLocation.x / self.tableSize.width;
    for (UIView *cell in self.displayCellArray) {
        if ([self p_indexForCell:cell] == index) {
            return cell;
            break;
        }
    }
    return nil;
}

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
