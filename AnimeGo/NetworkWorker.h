//
//  NetworkWorker.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/28.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NetworkWorker : NSObject

@property (nonatomic) BOOL isWebLoading;
@property (nonatomic, readonly) BOOL isWorking;

+ (NetworkWorker *)sharedNetworkWorker;

- (void)requestCommand:(NSString *)command
        withParameters:(NSDictionary *)parameters
               success:(void (^)(id result))success
       connectionError:(void (^)(NSError *error))connectionError
           serverError:(void (^)(NSInteger error))serverError;

- (void)setImageURL:(NSString *)url forImageView:(UIImageView *)imageView;

@end
