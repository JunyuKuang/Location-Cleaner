//
//  PhotosHelper.h
//  LocationCleaner
//
//  Created by Jonny on 9/29/17.
//  Copyright © 2017 Jonny. All rights reserved.
//

@import UIKit;

@interface PhotosHelper : NSObject

- (void)removeLocationTagsForAssets:(NSArray *)assets handler:(void (^)(BOOL success, NSError *error))handler;
- (void)fetchAssetsHasLocationWithCompletionHandler:(void (^)(NSArray *assets))completionHandler;

@end
