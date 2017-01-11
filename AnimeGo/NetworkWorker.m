//
//  NetworkWorker.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/11/28.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "NetworkWorker.h"
#import "AFNetworking.h"
#import "NetworkConstant.h"
#import "SDWebImage/UIImageView+WebCache.h"

static NSString * const kRequestURL = @"https://lainiwakura.com/animego/request.php";
static NSString * const kImageURL = @"https://lainiwakura.com/animego/image/";
static const NSTimeInterval kTimeoutInterval = 20;

@interface NetworkWorker ()

@property (nonatomic) AFNetworkReachabilityStatus networkStatus;
@property (strong, nonatomic) AFHTTPSessionManager *sessionManager;
@property (readonly, nonatomic) NSDictionary *accountInfo;
@property (strong, nonatomic) NSMutableSet *workerIdentifierSet;
@property (nonatomic, readwrite) BOOL isRequesting;
@property (strong, nonatomic) UIImage *placeholderImage;

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
                [[NSNotificationCenter defaultCenter] postNotificationName:ContentNeedUpdateNofification
                                                                    object:self];
            }
            sharedNetworkWorker.networkStatus = status;
        }];
        
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    });
    
    return sharedNetworkWorker;
}

#pragma mark - Private Properties

- (AFHTTPSessionManager *)sessionManager {
    if (!_sessionManager) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        _sessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
        _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        _sessionManager.requestSerializer.timeoutInterval = kTimeoutInterval;
    }
    return _sessionManager;
}

- (NSMutableSet *)workerIdentifierSet {
    if (!_workerIdentifierSet) _workerIdentifierSet = [[NSMutableSet alloc] init];
    return _workerIdentifierSet;
}

- (void)setIsRequesting:(BOOL)isRequesting {
    _isRequesting = isRequesting;
    [self updateIndicatorVisible];
}

- (void)setIsWebLoading:(BOOL)isWebLoading {
    _isWebLoading = isWebLoading;
    [self updateIndicatorVisible];
}

#pragma mark - Private Methods

- (void)updateIndicatorVisible {
    BOOL isWorking = self.isRequesting || self.isWebLoading;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = isWorking;
}

#pragma mark - Public Methods

- (void)requestCommand:(NSString *)command
        withParameters:(NSDictionary *)parameters
               success:(void (^)(id result))success
       connectionError:(void (^)(NSError *error))connectionError
           serverError:(void (^)(NSInteger error))serverError {
    
    AFHTTPSessionManager *manager = self.sessionManager;
    NSMutableDictionary *finalParameters = [[NSMutableDictionary alloc] init];
    [finalParameters setValue:command forKey:@"command"];
    [finalParameters setValue:parameters forKey:@"args"];
    
    NSLog(@"Request: %@", finalParameters);
    
    self.isRequesting = YES;
    [manager POST:kRequestURL
       parameters:finalParameters
         progress:nil
          success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
              NSLog(@"Response: %@", responseObject);
              if (![manager.tasks count]) {
                  self.isRequesting = NO;
              }
              NSInteger error = AGErrorUnknownError;
              if ([responseObject isKindOfClass:[NSDictionary class]]) {
                  NSDictionary *dict = (NSDictionary *)responseObject;
                  if ([[dict objectForKey:@"error"] isKindOfClass:[NSNumber class]]) {
                      error = [(NSNumber *)(dict[@"error"]) integerValue];
                      if (error == AGErrorOk) {
                          if (success) success([dict valueForKey:@"result"]);
                          return;
                      }
                  }
              }
              if (serverError) serverError(error);
          }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
              NSLog(@"Error: %@", error);
              NSLog(@"%@", task.response);
              if (![manager.tasks count]) {
                  self.isRequesting = NO;
              }
              if (connectionError) connectionError(error);
          }];
}

- (void)setImageURL:(NSString *)url forImageView:(UIImageView *)imageView {
    NSURL *completeURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kImageURL, url]];
    [imageView sd_setImageWithURL:completeURL placeholderImage:self.placeholderImage];
}

@end
