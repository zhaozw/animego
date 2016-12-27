//
//  BangumiDetailViewController.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/26.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FetcherViewController.h"
#import "Bangumi+Create.h"
#import "RoundRectSwitcher.h"

@interface BangumiDetailViewController : FetcherViewController
<UICollectionViewDelegate, UICollectionViewDataSource, RoundRectSwitcherDelegate, UIPopoverPresentationControllerDelegate>

@property (strong, nonatomic) NSNumber *bangumiIdentifier;

@end
