//
//  ViewController.h
//  Bump
//
//  Created by Apprentice on 7/18/15.
//  Copyright (c) 2015 Bump Boys!, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "MySupplementaryViewCollectionReusableView.h"
#import "UIViewController+ViewController.h"
#import "User.h"

@interface ViewController : UICollectionViewController<
    CLLocationManagerDelegate> {
    CLLocationManager *_locationManager;
    BOOL updatingImageData;
}

@property(nonatomic, strong) NSMutableArray *users;
@property(nonatomic, strong) NSArray * dataArray;
@property(nonatomic, strong) NSArray * nameArray;
- (void)addressBookAuth;
- (void)updateUsers:(NSDictionary *)dict;
- (IBAction)dismissLoginScreen:(UIStoryboardSegue*)sender;

@end

