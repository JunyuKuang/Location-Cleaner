//
//  PhotosHelper.m
//  LocationCleaner
//
//  Created by Jonny on 9/29/17.
//  Copyright © 2017 Jonny. All rights reserved.
//

#import "PhotosHelper.h"
@import Photos;

@implementation PhotosHelper

/**
 Remove location tags for indicated Photo Library assets.
 
 @param assets An array of PHAsset. Assets that need to remove location tag.
 @param handler Will be called on main queue once completed.
 */
- (void)removeLocationTagsForAssets:(NSArray *)assets handler:(void (^)(BOOL success, NSError *error))handler
{
    __block UIBackgroundTaskIdentifier backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
    }];
    
    [PHPhotoLibrary.sharedPhotoLibrary performChanges:^{
        for (PHAsset *asset in assets) {
            [PHAssetChangeRequest changeRequestForAsset:asset].location = nil;
        }
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (handler) {
                handler(success, error);
            }
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
        }];
    }];
}

/**
 Fetch photo assets and video assets which contains location tags from user's Photo Library.

 @param completionHandler An array of PHAsset. Will be called on main queue.
 */
- (void)fetchAssetsHasLocationWithCompletionHandler:(void (^)(NSArray *assets))completionHandler
{
    __block UIBackgroundTaskIdentifier backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
    }];
    
    [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.includeHiddenAssets = YES;
        
        PHFetchResult *fetchResult = [PHAsset fetchAssetsWithOptions:options];
        NSMutableArray *assets = [[NSMutableArray alloc] init];
        
        for (NSInteger i = 0; i < fetchResult.count; i++) {
            PHAsset *asset = fetchResult[i];
            if (asset.location != nil) {
                [assets addObject:asset];
            }
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (completionHandler) {
                completionHandler(assets);
            }
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
        }];
    }];
}

@end
