//
//  BangumiCollectionViewCell.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/29.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Bangumi+Create.h"

@interface BangumiCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) Bangumi *bangumi;

+ (CGSize)calcSizeWithWidth:(CGFloat)width;

@end
