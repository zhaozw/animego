//
//  AppDelegate+CoreData.m
//  AnimeGo
//
//  Created by Chaoran Li on 2017/1/15.
//  Copyright © 2017年 Chaoran Li. All rights reserved.
//

#import "AppDelegate+CoreData.h"

@implementation AppDelegate (CoreData)

- (RACSignal *)asyncOperationWithPrivateMOC:(void (^)(NSManagedObjectContext *))operation {
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        NSManagedObjectContext *mainMOC = self.mainMOC;
        NSManagedObjectContext *privateMOC = self.privateMOC;
        
        [privateMOC performBlock:^{
            operation(privateMOC);
            NSError *privateError = nil;
            if (![privateMOC save:&privateError]) {
                [subscriber sendError:privateError];
            }
            
            [mainMOC performBlock:^{
                NSError *mainError = nil;
                if (![mainMOC save:&mainError]) {
                    [subscriber sendError:mainError];
                }
                [subscriber sendNext:nil];
                [subscriber sendCompleted];
            }];
        }];
        
        return nil;
    }];
}

@end
