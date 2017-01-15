//
//  DailyDeliveryViewController.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/25.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FetcherViewController.h"
#import "HorizontalTableView.h"
#import "VerticalTableView.h"

@interface DailyDeliveryViewController : FetcherViewController
<HorizontalTableViewDelegate, HorizontalTableViewDataSource,
VerticalTableViewDelegate, VerticalTableViewDataSource,
UIViewControllerPreviewingDelegate>

@end
