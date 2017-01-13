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

@interface BangumiDetailViewController : FetcherViewController
<UICollectionViewDelegate, UICollectionViewDataSource, UIPopoverPresentationControllerDelegate>

@property (nonatomic, strong) NSNumber *bangumiIdentifier;

@end
