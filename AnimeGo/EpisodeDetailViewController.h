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

@property (readonly, nonatomic) NSString *url;

@property (strong, nonatomic) NSNumber *bangumiIdentifier;
@property (strong, nonatomic) NSNumber *episodeNumber;

@end
