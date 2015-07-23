//
//  ViewController.m
//  Bump
//
//  Created by Apprentice on 7/18/15.
//  Copyright (c) 2015 Bump Boys!, Inc. All rights reserved.
//

#import "ViewController.h"
#import "Cell.h"
#import "AppDelegate.h"
#import "QuartzCore/QuartzCore.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
@import CoreLocation;
@import AddressBook;

@interface ViewController () <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSOperationQueue *bgQueue;
@property (strong, nonatomic) NSMutableArray *imageData;
@property (assign, nonatomic) CFErrorRef *error;
@property (assign, nonatomic) BOOL *hasBeenChecked;
@property (assign, nonatomic) BOOL *contactsHasBeenChecked;

@end

@implementation ViewController{
    float *prevLat;
    float *prevLong;

}

/// ASYNCHRONOUS REQUEST CODE ///

-(void)makeRequest:(NSString*)string
{
    NSLog(@"You are in the MakeRequest method");
    NSString *location = string;
    NSString *prefix = @"https://whispering-stream-9304.herokuapp.com/update?lat=";
    NSString *queryString = [prefix stringByAppendingString:location];
    [self loadURLsFromLocation:queryString];
}


- (void)viewDidAppear:(BOOL)animated{
    NSLog(@"viewDidAppear1");
    [super viewDidAppear:animated];
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"]){
        [self performSegueWithIdentifier:@"firstLogin" sender:self];
    }
    else
    {
    
    //     This conditional block of code is for push notifications
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)])
        {
        // iOS 8 Notifications
        // use registerUserNotificationSettings
            NSLog(@"registerUserNotificationSettings");
            [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound |         UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        }
        else
        {
            // iOS < 8 Notifications
            // use registerForRemoteNotifications
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes: UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert];
        }
        
        if (self.hasBeenChecked != YES){
            NSLog(@"address Book auth call");
             [self addressBookAuth];
        }
        
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self.locationManager requestAlwaysAuthorization];
        }
        NSLog(@" You are in viewDidAppear2");
    }
    
}
- (void)viewDidLoad {

    [super viewDidLoad];
    self.dataArray = @[];
    self.nameArray = @[];
    self.imageData = [[NSMutableArray alloc] init];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    NSLog(@"You are in viewDidLoad1");
    [self.locationManager startUpdatingLocation];

    if (self.contactsHasBeenChecked == YES){
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, self.error);
        [self performSelector:@selector(listPeopleInAddressBook:) withObject:(__bridge id)(addressBook) afterDelay:0.0];
//        [self listPeopleInAddressBook:addressBook];
        // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
        // This is the notification block of code specifically for location.
    }
    NSLog(@"You are in viewDidLoad2");

 
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



// THESE ARE THE COLLECTION VIEW DELEGATE METHODS///


-(NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    NSLog(@"You are in numberOfSectionsInCollectionView");
    return 1;
}


-(NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    NSLog(@"%lu", (unsigned long)self.dataArray.count);
    
    return self.dataArray.count;
}

-(UICollectionViewCell*) collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"collectionView:cellForItemAtIndexPath");

    Cell *aCell = [cv dequeueReusableCellWithReuseIdentifier:@"myCell" forIndexPath:indexPath];
    UIImageView *imageView = (UIImageView *)[cv viewWithTag:1];
    imageView.image = (UIImage *)[self.imageData objectAtIndex:indexPath.row];
//    NSString *names = (NSString *)[self.nameArray objectAtIndex:indexPath.row];
    
    [imageView.layer setMasksToBounds:YES];
    [imageView.layer setBorderColor:[UIColor whiteColor].CGColor];
    [imageView.layer setBorderWidth:1];
    [imageView.layer setCornerRadius:40];
    
    
    
    UILabel *title = [[UILabel alloc]initWithFrame:CGRectMake(23, 70, aCell.bounds.size.width, 40)];
    title.tag = 200;
    [aCell.contentView addSubview:title];
    [title setFont:[UIFont fontWithName:@"AmericanTypewriter-Condensed" size:14.0]];

//    [title setText:names];
    
    return aCell;
    
}


// HEADER CODE ///


-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"You are in collectionView:viewForSupplementaryElementaryOfKind:atIndexPath");
    MySupplementaryViewCollectionReusableView *header = nil;
    if ([kind isEqual:UICollectionElementKindSectionHeader])
    {
        header = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                    withReuseIdentifier:@"MyHeader"
                                                           forIndexPath:indexPath];
        
        header.headerLabel.text = @"bump";
        [header.headerLabel setFont:[UIFont fontWithName:@"AmericanTypewriter-Condensed" size:34.0]];
    }
    return header;
}





//// LOCATION CODE /////

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    NSLog(@"You are in locationManager");
    [NSThread sleepForTimeInterval:0.5f];
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    [self.locationManager startUpdatingLocation];
    //    [self.locationManager stopUpdatingLocation];
    
    CLLocation *location = [self.locationManager location];
    CLLocationCoordinate2D coordinate = [location coordinate];
    float longitude=coordinate.longitude;
    float latitude=coordinate.latitude;
    
    
    
    /// MOVEMENT TOLERANCE
    //    if (prevLat == nil){
    //        prevLat = &latitude;
    //    }
    //    else if (prevLat == &latitude){
    //        [self.locationManager stopUpdatingLocation];
    //    }
    //    if (prevLat !=
    //    NSLog(@"We're in the request maker.");
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *token = appDelegate.pushCode;
    
    //    NSLog(@"%f", latitude);
  [self makeRequest:[NSString stringWithFormat:@"%f&lon=%f&token=%@",latitude,longitude,token]];
//    [self makeRequest:[NSString stringWithFormat:@"%f&lon=%f&token=%@",latitude,longitude]];
}

- (void)loadURLsFromLocation:(NSString *)locationString {
    NSLog(@"Yuo are in loadUrlsFromLoc");
    if(!self.bgQueue){
        self.bgQueue = [[NSOperationQueue alloc] init]; // Background threads it (backgroundqueue).
    }
    
    [NSURLConnection sendAsynchronousRequest:
     [NSURLRequest requestWithURL:
      [NSURL URLWithString:locationString]]
                                       queue:self.bgQueue
                           completionHandler: ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if(connectionError){
                                   NSLog(@"there was a connection error%@", connectionError);
                               }
                               
                               if(data != nil){
                                   
                                   NSDictionary *imagesDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                                   NSLog(@"here is the hash from pete%@", imagesDict);
//                                   NSDictionary *peteData = [imagesDict valueForKey:@"data"];
                                   NSArray *urls = [imagesDict valueForKey:@"images"];
//                                   NSArray *names = [peteData valueForKey:@"names"];
//                                   NSLog(@"Your names%@", names);
                                   NSLog(@"your urls%@", urls);
//                                   self.nameArray = names;
                                   self.dataArray = urls;
                                   [self updateImageData];
                               }
                               
                           }];
}

- (void)updateImageData{
    NSLog(@"You are in updateImageData");

    __block NSInteger count = self.dataArray.count;
    
    for (NSInteger i = 0; i< self.dataArray.count; i++) {
        if(!self.bgQueue){
            self.bgQueue = [[NSOperationQueue alloc] init];
        }
        
        [NSURLConnection sendAsynchronousRequest:
         [NSURLRequest requestWithURL:
          [NSURL URLWithString:self.dataArray[i]]]
                                           queue:self.bgQueue
                               completionHandler: ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                   if(data){
                                       self.imageData[i] = [UIImage imageWithData:data];
                                   }
                                   
                                   count -= 1;
                                   if(count <= 0){
                                       [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            
                                           [self.collectionView reloadData];
                                       }];
                                   }
                               }];
    }
}




// Address Book Methods
-(void)addressBookAuth
{
    NSLog(@"You are in addressBookAuth");
    self.hasBeenChecked = YES;
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    
    if (status == kABAuthorizationStatusDenied || status == kABAuthorizationStatusRestricted) {
        // if you got here, user had previously denied/revoked permission for your
        // app to access the contacts, and all you can do is handle this gracefully,
        // perhaps telling the user that they have to go to settings to grant access
        // to contacts
        
        [[[UIAlertView alloc] initWithTitle:nil message:@"This app requires access to your contacts to function properly. Please visit to the \"Privacy\" section in the iPhone Settings app." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }
    
    self.contactsHasBeenChecked = YES;
    self.error = NULL;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, self.error);
    
    if (!addressBook) {
        NSLog(@"ABAddressBookCreateWithOptions error: %@", CFBridgingRelease(self.error));
        return;
    }
    
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        if (self.error) {
            NSLog(@"ABAddressBookRequestAccessWithCompletion error: %@", CFBridgingRelease(error));
        }

        
        if (granted) {
            // if they gave you permission, then just carry on
//            [self listPeopleInAddressBook:addressBook];
             [self performSelector:@selector(listPeopleInAddressBook:) withObject:(__bridge id)(addressBook) afterDelay:0.0];
        } else {
            // however, if they didn't give you permission, handle it gracefully, for example...
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // BTW, this is not on the main thread, so dispatch UI updates back to the main queue
                
                [[[UIAlertView alloc] initWithTitle:nil message:@"This app requires access to your contacts to function properly. Please visit to the \"Privacy\" section in the iPhone Settings app." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            });
            
        }
        
        CFRelease(addressBook);
    });
}



-(void)listPeopleInAddressBook:(ABAddressBookRef *) addressBook {
    
    
    NSArray *allPeople = CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(addressBook));
    NSInteger numberOfPeople = [allPeople count];
    
    //        NSLog(@"This is the number of people in my contacts");
    //        NSLog(@"%ld", (long)numberOfPeople);
    
    NSMutableDictionary *contactDictionary = [[NSMutableDictionary alloc] init];
    
    for (NSInteger i = 0; i < numberOfPeople; i++) {
        
        ABRecordRef person = (__bridge ABRecordRef)allPeople[i];
        NSString *firstName = CFBridgingRelease(ABRecordCopyValue(person, kABPersonFirstNameProperty));
        //            NSLog(@"%@", firstName);
        NSString *lastName  = CFBridgingRelease(ABRecordCopyValue(person, kABPersonLastNameProperty));
        //            NSLog(@"%@", lastName);
        NSData  *imgData = (NSData *)CFBridgingRelease(ABPersonCopyImageData(person));
        UIImage  *img = [UIImage imageWithData:imgData];
        
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
        NSString *mobileNumber;
        // NSString *mobileLabel;
        NSInteger numbertotal = ABMultiValueGetCount(phoneNumbers);
        for (NSInteger x=0; x < numbertotal; x++){
            //mobileLabel = CFBridgingRelease(ABMultiValueCopyLabelAtIndex(phoneNumbers, i));
            //              NSLog(@"%@", mobileLabel);
            //              if ([mobileLabel isEqualToString:@"_$!<mobile>!$_"]) {
            mobileNumber = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers,x);
            //                    NSLog(@"Name:%@ %@, and Mobile: %@, and image: %@", firstName, lastName, mobileNumber, img);
            //            }
            
            
            //            Setting Up Post request for contact information
            
            NSMutableDictionary *thisPerson = [[NSMutableDictionary alloc] init];
            if (firstName){
                [thisPerson setObject:firstName forKey:@"first_name"];
            }
            if (lastName){
                [thisPerson setObject:lastName forKey:@"last_name" ];
            }
            if (img){
                //                    [thisPerson setObject:img forKey:@"image"];
            }
            if (mobileNumber){
                [thisPerson setObject:mobileNumber forKey:@"number"];
            }
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            NSString *token = appDelegate.pushCode;
            
            //                NSLog(@"the token is%@", token);
            [thisPerson setObject:token forKey:@"user_token"];\
            NSString *key = [NSString stringWithFormat:@"person%d", i];
            NSLog(@"%@", key);
            [contactDictionary setObject:thisPerson forKey:key];
        }
    }
    
    // NSMutableDictionary *contactsToServer = [[NSMutableDictionary alloc] init];
    //            NSDictionary *jsonDictionary = [[NSMutableDictionary alloc] init];
    //[contactsToServer setObject:contactArray forKey:@"contacts"];
    
    //            NSString *jsonString = [contactsToServer JSONRepresentation];
    NSError *err = nil;
    NSData *contactsToServer = [NSJSONSerialization dataWithJSONObject:contactDictionary options:0 error:&err];
    NSLog(@"ERROR - %@", err);
    //            NSLog(@"%@", contactsToServer);
    
    
    // NSLog(@"%@", thisPerson);
    
    if(!self.bgQueue){
        self.bgQueue = [[NSOperationQueue alloc] init]; // Background threads it (backgroundqueue).
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"https://whispering-stream-9304.herokuapp.com/contacts"]];
    //            [request setURL:[NSURL URLWithString:@"localhost:3000/contacts"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:contactsToServer];
    
    
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    NSLog(@"%@", conn);
    
    if(conn) {
        NSLog(@"Connection Made");
        
    }
    else {
        NSLog(@"Connection Failed");
    }
    
    //            [NSURLConnection sendAsynchronousRequest:request
    //                                               queue:self.bgQueue
    //                                   completionHandler: ^{ NSLog(@"Finished the request");}];
    //             ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
    //                                       if(connectionError){
    //                                           NSLog(@"%@", connectionError);
    //                                       }
    //
    //                                       if(data != nil){
    //
    //                                           NSDictionary *imagesDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    //                                           NSArray *urls = [imagesDict valueForKey:@"images"];
    //                                           //                                   NSLog(@"%@", urls);
    //                                           self.dataArray = urls;
    //                                           [self updateImageData];
    //                                       }
    
    
    //                                   }];
    
}












@end
