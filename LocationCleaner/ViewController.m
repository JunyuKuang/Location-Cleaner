//
//  ViewController.m
//  PhotoLocationRemover
//
//  Created by Jonny on 9/28/17.
//  Copyright © 2017 Jonny. All rights reserved.
//

#import "ViewController.h"
#import "PhotosHelper.h"

@import Photos;

typedef NS_ENUM(NSInteger, ViewControllerState) {
    ViewControllerStateNoPhotosAccess = 0,
    ViewControllerStateLoadingAssets,
    ViewControllerStateWaitingForDeletion,
    ViewControllerStateDeletingLocations
};

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *hintLabel;
@property (weak, nonatomic) IBOutlet UIButton *commitButton;

@property (strong, nonatomic) NSArray *assets;
@property (strong, nonatomic) PhotosHelper *photosHelper;

@property (nonatomic) ViewControllerState state;

@end

@implementation ViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.assets = @[];
    self.photosHelper = [[PhotosHelper alloc] init];
    self.state = ViewControllerStateLoadingAssets;
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (status == PHAuthorizationStatusAuthorized) {
                [self refetchAssetsAndUpdateState];
            } else {
                self.state = ViewControllerStateNoPhotosAccess;
            }
        }];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForegroundNotification)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)appWillEnterForegroundNotification
{
    if (self.state == ViewControllerStateWaitingForDeletion) {
        [self refetchAssetsAndUpdateState];
    }
}

- (void)setState:(ViewControllerState)state
{
    _state = state;
    
    if (state == ViewControllerStateNoPhotosAccess) {
        self.commitButton.backgroundColor = UIColor.blackColor;
        [self.commitButton setTitle:NSLocalizedString(@"Open Settings", nil) forState:UIControlStateNormal];
    } else {
        self.commitButton.backgroundColor = UIColor.redColor;
        [self.commitButton setTitle:NSLocalizedString(@"Remove Location Tags", nil) forState:UIControlStateNormal];
    }
    
    switch (state) {
        case ViewControllerStateNoPhotosAccess:
            self.hintLabel.text = NSLocalizedString(@"Cannot access Photo Library", nil);
            self.commitButton.enabled = YES;
            break;
            
        case ViewControllerStateLoadingAssets:
            self.hintLabel.text = NSLocalizedString(@"Loading photos and videos...", nil);
            self.commitButton.enabled = NO;
            break;
            
        case ViewControllerStateWaitingForDeletion:
            if (self.assets.count > 1) {
                self.hintLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Found %i photos and videos have location tags", nil), self.assets.count];
                self.commitButton.enabled = YES;
            } else if (self.assets.count == 1) {
                self.hintLabel.text = NSLocalizedString(@"Found 1 photo or video has location tag", nil);
                self.commitButton.enabled = YES;
            } else {
                NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
                
                UIFont *titleFont;
                if (@available(iOS 8.2, *)) {
                    titleFont = [UIFont systemFontOfSize:26.0f weight:UIFontWeightSemibold];
                } else {
                    titleFont = [UIFont systemFontOfSize:26.0f];
                }
                UIFont *subtitleFont;
                if (@available(iOS 8.2, *)) {
                    subtitleFont = [UIFont systemFontOfSize:18.0f weight:UIFontWeightSemibold];
                } else {
                    subtitleFont = [UIFont systemFontOfSize:18.0f];
                }
                
                [string appendAttributedString: [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@", NSLocalizedString(@"No photo or video have location tag", nil), @"\n\n"] attributes:@{NSFontAttributeName : titleFont}]];
                [string appendAttributedString: [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Disable Camera's location service in \"Settings > Privacy > Location Services > Camera\" to prevent new photos and videos from tagging location", nil) attributes:@{NSFontAttributeName : subtitleFont}]];
                
                self.hintLabel.attributedText = string;
                self.commitButton.enabled = NO;
            }
            break;
            
        case ViewControllerStateDeletingLocations:
            self.hintLabel.text = NSLocalizedString(@"Removing location tags...", nil);
            self.commitButton.enabled = NO;
            break;
            
        default:
            break;
    }
}

- (IBAction)tapCommitButton:(UIButton *)sender
{
    switch (self.state) {
        case ViewControllerStateNoPhotosAccess: {
            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [UIApplication.sharedApplication openURL:url];
            break;
        }
        case ViewControllerStateWaitingForDeletion: {
            [self presentConfirmationAlertWithCompletionHandler:^(BOOL confirmed) {
                if (confirmed) {
                    self.state = ViewControllerStateDeletingLocations;
                    [self.photosHelper removeLocationTagsForAssets:self.assets handler:^(BOOL success, NSError *error) {
                        [self refetchAssetsAndUpdateState];
                        if (error != nil) {
                            NSLog(@"Remove location tags error: %@", error);
                        }
                    }];
                }
            }];
            break;
        }
        default:
            break;
    }
}

- (void)refetchAssetsAndUpdateState
{
    self.state = ViewControllerStateLoadingAssets;
    [self.photosHelper fetchAssetsHasLocationWithCompletionHandler:^(NSArray *assets) {
        self.assets = assets;
        self.state = ViewControllerStateWaitingForDeletion;
    }];
}

- (void)presentConfirmationAlertWithCompletionHandler:(void (^)(BOOL granted))completionHandler
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Remove Location Tags for All of Your Photos and Videos", nil)
                                                                   message:NSLocalizedString(@"This will sync to all of your other iCloud Photo Library enabled devices and cannot be undone.", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                if (completionHandler) {
                                                    completionHandler(NO);
                                                }
                                            }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Remove Location Tags", nil)
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                if (completionHandler) {
                                                    completionHandler(YES);
                                                }
                                            }]];

    [self presentViewController:alert animated:YES completion:nil];
}

@end
