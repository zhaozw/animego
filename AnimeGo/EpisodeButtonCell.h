//
//  EpisodeButtonCell.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/13.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, EpisodeButtonCellStatus) {
    EpisodeButtonCellStatusNotReleased = 0,
    EpisodeButtonCellStatusReleased    = 1,
    EpisodeButtonCellStatusWatched     = 2
};

@interface EpisodeButtonCell : UICollectionViewCell

@property (strong, nonatomic) NSString *title;
@property (nonatomic) EpisodeButtonCellStatus status;

@end
