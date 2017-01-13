//
//  EpisodeDetailViewController.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/3.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "FetcherViewController.h"

@interface EpisodeDetailViewController : FetcherViewController

@property (nonatomic, readonly) NSString *url;

@property (nonatomic, strong) NSNumber *bangumiIdentifier;
@property (nonatomic, strong) NSNumber *episodeNumber;

@end
