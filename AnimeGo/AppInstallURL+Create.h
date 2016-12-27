//
//  AppInstallURL+Create.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/6.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import "AppInstallURL+CoreDataClass.h"

@interface AppInstallURL (Create)

+ (AppInstallURL *)createAppInstallURLWithDictionary:(NSDictionary *)appInstallURLDictionary
                              inManagedObjectContext:(NSManagedObjectContext *)context;

+ (AppInstallURL *)getAppInstallURLWithName:(NSString *)name
                     inManagedObjectContext:(NSManagedObjectContext *)context;
    
@end
