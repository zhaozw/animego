//
//  NetworkWorker.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/28.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <ReactiveObjC.h>

@interface NetworkWorker : NSObject

+ (NetworkWorker *)sharedNetworkWorker;

- (RACSignal *)requestCommand:(NSString *)command
               withParameters:(NSDictionary *)parameters
                  uniqueToken:(NSString *)uniqueToken;

- (void)setImageURL:(NSString *)url forImageView:(UIImageView *)imageView;

@end
