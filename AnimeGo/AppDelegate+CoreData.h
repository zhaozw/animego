//
//  AppDelegate+CoreData.h
//  AnimeGo
//
//  Created by Chaoran Li on 2017/1/15.
//  Copyright © 2017年 Chaoran Li. All rights reserved.
//

#import "AppDelegate.h"

#import <ReactiveObjC.h>

@interface AppDelegate (CoreData)

- (RACSignal *)asyncOperationWithPrivateMOC:(void (^)(NSManagedObjectContext *))operation;

@end
