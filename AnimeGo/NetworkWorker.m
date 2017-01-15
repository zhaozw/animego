//
//  NetworkWorker.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/28.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "NetworkWorker.h"

#import <SDWebImage/UIImageView+WebCache.h>
#import "AFNetworking.h"
#import "NetworkConstant.h"
#import "NotificationManager.h"

static NSString * const kRequestURL = @"https://lainiwakura.com/animego/request.php";
static NSString * const kImageURL = @"https://lainiwakura.com/animego/image/";
static const NSTimeInterval kTimeoutInterval = 20;

@interface NetworkWorker ()

@property (nonatomic, assign) AFNetworkReachabilityStatus networkStatus;
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic, assign, readwrite) BOOL isRequesting;
@property (nonatomic, strong) UIImage *placeholderImage;
@property (nonatomic, strong) NSMutableSet *uniqueTokenSet;

@end

@implementation NetworkWorker

#pragma mark - Singleton

+ (NetworkWorker *)sharedNetworkWorker {
    static NetworkWorker *sharedNetworkWorker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedNetworkWorker = [[NetworkWorker alloc] init];
        sharedNetworkWorker.placeholderImage = [UIImage imageNamed:@"placeholder"];
        sharedNetworkWorker.networkStatus = [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;

        [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            if (sharedNetworkWorker.networkStatus != status) {
                sharedNetworkWorker.networkStatus = status;
                [[NSNotificationCenter defaultCenter] postNotificationName:AGContentNeedUpdateNofification
                                                                    object:self];
            }
        }];
        
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    });
    
    return sharedNetworkWorker;
}

#pragma mark - Private Methods

- (AFHTTPSessionManager *)sessionManager {
    if (!_sessionManager) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        _sessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
        _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        _sessionManager.requestSerializer.timeoutInterval = kTimeoutInterval;
    }
    return _sessionManager;
}

- (NSMutableSet *)uniqueTokenSet {
    if (!_uniqueTokenSet) _uniqueTokenSet = [[NSMutableSet alloc] init];
    return _uniqueTokenSet;
}

- (void)setIsRequesting:(BOOL)isRequesting {
    _isRequesting = isRequesting;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = isRequesting;
}

#pragma mark - Public Methods

- (RACSignal *)requestCommand:(NSString *)command
               withParameters:(NSDictionary *)parameters
                  uniqueToken:(NSString *)uniqueToken {
    
    AFHTTPSessionManager *manager = self.sessionManager;
    NSMutableDictionary *finalParameters = [[NSMutableDictionary alloc] init];
    [finalParameters setValue:command forKey:@"command"];
    [finalParameters setValue:parameters forKey:@"args"];
    
    @weakify (self)
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify (self)
        
        if (self.networkStatus <= 0) {
            NSError *unavailableError = [NSError errorWithDomain:AGErrorDomain
                                                            code:AGErrorClientNetworkUnavailable
                                                        userInfo:nil];
            [subscriber sendError:unavailableError];
            return nil;
        }
        
        if (uniqueToken) {
            if ([self.uniqueTokenSet containsObject:uniqueToken]) {
                NSError *duplicateError = [NSError errorWithDomain:AGErrorDomain
                                                                code:AGErrorClientDuplicateRequest
                                                            userInfo:nil];
                [subscriber sendError:duplicateError];
                return nil;
            }
            [self.uniqueTokenSet addObject:uniqueToken];
        }
        
        self.isRequesting = YES;
        [manager
         POST:kRequestURL
         parameters:finalParameters
         progress:nil
         success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
             
             if (![manager.tasks count]) self.isRequesting = NO;
             if (uniqueToken) [self.uniqueTokenSet removeObject:uniqueToken];
             AGErrorCode serverErrorCode = AGErrorServerUnknownError;
             if ([responseObject isKindOfClass:[NSDictionary class]]) {
                 NSDictionary *dict = (NSDictionary *)responseObject;
                 if ([[dict objectForKey:@"error"] isKindOfClass:[NSNumber class]]) {
                     serverErrorCode = ((NSNumber *) (dict[@"error"])).integerValue;
                     if (serverErrorCode == AGErrorServerOk) {
                         [subscriber sendNext:[dict valueForKey:@"result"]];
                         [subscriber sendCompleted];
                         return;
                     }
                 }
             }
             NSError *serverError = [NSError errorWithDomain:AGErrorDomain
                                                        code:serverErrorCode
                                                    userInfo:nil];
             [subscriber sendError:serverError];
         }
         failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
             NSLog(@"Error: %@", error);
             NSLog(@"%@", task.response);
             if (![manager.tasks count]) self.isRequesting = NO;
             [subscriber sendError:error];
         }];
        
        return nil;
    }];
    
    return signal;
}

- (void)setImageURL:(NSString *)url forImageView:(UIImageView *)imageView {
    NSURL *completeURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kImageURL, url]];
    [imageView sd_setImageWithURL:completeURL placeholderImage:self.placeholderImage];
}

@end
