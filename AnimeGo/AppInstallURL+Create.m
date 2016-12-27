//
//  AppInstallURL+Create.m
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/6.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "AppInstallURL+Create.h"
#import "NetworkConstant.h"

NSString * const kEntityNameAppInstallURL = @"AppInstallURL";

@implementation AppInstallURL (Create)

+ (AppInstallURL *)createAppInstallURLWithDictionary:(NSDictionary *)appInstallURLDictionary
                         inManagedObjectContext:(NSManagedObjectContext *)context {

    NSString *name = appInstallURLDictionary[AGAppInstallURLKeyName];
    AppInstallURL *appInstallURL = [AppInstallURL getAppInstallURLWithName:name
                                                    inManagedObjectContext:context];

    if (!appInstallURL) {
        appInstallURL = [NSEntityDescription insertNewObjectForEntityForName:kEntityNameAppInstallURL
                                                      inManagedObjectContext:context];
    }
    
    appInstallURL.name = name;
    appInstallURL.installurl = appInstallURLDictionary[AGAppInstallURLKeyInstallURL];
    
    return appInstallURL;
}

+ (AppInstallURL *)getAppInstallURLWithName:(NSString *)name
                inManagedObjectContext:(NSManagedObjectContext *)context {
    
    AppInstallURL *appInstallURL = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"AppInstallURL"];
    request.predicate = [NSPredicate predicateWithFormat:@"name = %@", name];
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (error || [matches count] > 1) {
        // TODO
        NSLog(@"Client database error.");
        return nil;
    }
    
    if (!matches) return nil;
    
    if ([matches count]) {
        appInstallURL = [matches firstObject];
    }
    
    return appInstallURL;
}

@end
