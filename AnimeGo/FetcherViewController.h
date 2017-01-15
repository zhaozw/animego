//
//  FetcherViewController.h
//  AnimeGo
//
//  Created by Chaoran Li on 2016/12/5.
//  Copyright © 2016年 Chaoran Li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface FetcherViewController : UIViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, weak) NSManagedObjectContext *mainMOC;

- (NSFetchRequest *)fetchRequest;
- (NSTimeInterval)autoRefreshTimeInterval;
- (BOOL)hasRefreshButton;
- (void)fetchRemoteData;
- (void)updateUI;
- (void)alertConnectionError;

- (void)touchRefreshButton;
- (void)didBecomeActive;
- (void)willResignActive;
- (void)contentNeedUpdateNofification;
- (void)contentNeedReOrderNofification;
- (void)jumpToPage;

@end
