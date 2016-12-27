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

#define MAS_SHORTHAND
#import "Masonry.h"

static NSString * const kReuseIdentifier = @"Cell";
static NSInteger kAutoRefreshTimeInterval = 30 * 60;

@interface MyFavoriteViewController ()

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) NSBlockOperation *blockOperation;
@property (nonatomic) BOOL shouldReloadCollectionView;
@property (nonatomic) BOOL isFirstTimeAppear;
@property (nonatomic) BOOL isVisible;

@end

@implementation MyFavoriteViewController

#pragma mark - Life Cycle Methods

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
    layout.minimumLineSpacing = LCPadding;
    layout.minimumInteritemSpacing = LCPadding;
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
        make.left.equalTo(self.view.left);
        make.right.equalTo(self.view.right);
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

#pragma mark <UICollectionViewDataSource>

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

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    id object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if ([object isKindOfClass:[Bangumi class]]) {
        Bangumi *bangumi = (Bangumi *)object;
        [self.parentViewController performSegueWithIdentifier:kSegueIdentifier sender:bangumi.identifier];
    }
}

#pragma mark - Protected Methods

- (NSFetchRequest *)fetchRequest {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Bangumi"];
    request.predicate = [NSPredicate predicateWithFormat:@"isfavorite == TRUE"];
    NSSortDescriptor *isFavoriteSort = [NSSortDescriptor sortDescriptorWithKey:@"isfavorite" ascending:NO];
    NSSortDescriptor *hotSort = [NSSortDescriptor sortDescriptorWithKey:@"hot" ascending:NO];
    [request setSortDescriptors:@[isFavoriteSort, hotSort]];
    return request;
}

- (NSTimeInterval)autoRefreshTimeInterval {
    return kAutoRefreshTimeInterval;
}

- (void)updateUI {
    [self.collectionView reloadData];
}

#pragma mark - Private Methods

- (void)fetchRemoteData {
    [self fetchMyFavoriteSuccess:nil
                 connectionError:nil
                     serverError:nil];
}

@end
