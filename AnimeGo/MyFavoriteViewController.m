//
//  MyFavoriteViewController.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/29.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "MyFavoriteViewController.h"
#import "BangumiCollectionViewCell.h"
#import "MainViewController.h"
#import "LayoutConstant.h"

#import "AGRequest.h"

#define MAS_SHORTHAND
#import "Masonry.h"

static NSString * const kReuseIdentifier = @"Cell";
static NSInteger kAutoRefreshTimeInterval = 30 * 60;

@interface MyFavoriteViewController ()

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, assign) BOOL isFirstTimeAppear;

@end

@implementation MyFavoriteViewController

#pragma mark - UIViewController (super class)

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isFirstTimeAppear = YES;
    UIUserInterfaceIdiom deviceType = [[UIDevice currentDevice] userInterfaceIdiom];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    CGFloat minCollectionCellWidth = (deviceType == UIUserInterfaceIdiomPad)
        ? LCMinCollectionCellWidth : LCMinCollectionCellWidthPhone;
    NSInteger cellsInRow = self.view.frame.size.width / minCollectionCellWidth;
    if (cellsInRow == 0) cellsInRow = 1;
    CGFloat width = self.view.frame.size.width / cellsInRow - LCPadding;
    layout.itemSize = [BangumiCollectionViewCell calcSizeWithWidth:width];
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = LCPadding;
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.collectionView.contentInset = UIEdgeInsetsMake(LCPadding, LCPadding, LCPadding, LCPadding);
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[BangumiCollectionViewCell class] forCellWithReuseIdentifier:kReuseIdentifier];
    [self.view addSubview:self.collectionView];
    
    [self.collectionView makeConstraints:^(MASConstraintMaker *make) {
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
        [self.fetchedResultsController performFetch:nil];
        [self.collectionView reloadData];
    }
    self.isFirstTimeAppear = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.parentViewController.navigationItem.rightBarButtonItem = nil;
}

#pragma mark - FetcherViewController (super class)

- (void)contentNeedUpdateNofification {
    // Need not to fetch data here
    // MainViewController will fetch data
    [self updateUI];
}

- (void)didBecomeActive {
    // Need not to fetch data here
    // MainViewController will fetch data
    [self updateUI];
}

- (NSFetchRequest *)fetchRequest {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Bangumi"];
    request.predicate = [NSPredicate predicateWithFormat:@"isFavorite == TRUE"];
    NSSortDescriptor *prioritySort = [NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:NO];
    NSSortDescriptor *hotSort = [NSSortDescriptor sortDescriptorWithKey:@"hot" ascending:NO];
    [request setSortDescriptors:@[prioritySort, hotSort]];
    return request;
}

- (NSTimeInterval)autoRefreshTimeInterval {
    return kAutoRefreshTimeInterval;
}

- (void)updateUI {
    [self.collectionView reloadData];
}

- (void)fetchRemoteData {
    AGRequest *request = [[AGRequest alloc] init];
    [[request fetchMyFavorite] subscribeCompleted:^{ }];
}

#pragma mark - <UICollectionViewDataSource>

- (void)configureCell:(id)cell atIndexPath:(NSIndexPath*)indexPath {
    id object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if ([cell isKindOfClass:[BangumiCollectionViewCell class]]) {
        BangumiCollectionViewCell *bangumiCell = (BangumiCollectionViewCell *)cell;
        if ([object isKindOfClass:[Bangumi class]]) {
            Bangumi *bangumi = object;
            bangumiCell.bangumi = bangumi;
        }
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kReuseIdentifier
                                                                           forIndexPath:indexPath];
    
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

#pragma mark - <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    id object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if ([object isKindOfClass:[Bangumi class]]) {
        Bangumi *bangumi = (Bangumi *)object;
        [self.parentViewController performSegueWithIdentifier:AGShowDetailSegueIdentifier sender:bangumi.identifier];
    }
}

@end
