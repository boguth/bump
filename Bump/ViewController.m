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
@property (assign, nonatomic) BOOL hasBeenChecked;
@property (assign, nonatomic) BOOL contactsHasBeenChecked;
@property (assign, nonatomic) NSString *firstTimeChecked;

@end

@implementation ViewController{
    float *prevLat;
    float *prevLong;

}

/// ASYNCHRONOUS REQUEST CODE ///

-(void)makeRequest:(NSString*)string
{
    NSLog(@"%@ %@", NSStringFromSelector(_cmd), string);
    NSString *location = string;
    NSString *prefix = @"https://whispering-stream-9304.herokuapp.com/update?lat=";
    NSString *queryString = [prefix stringByAppendingString:location];
    [self loadURLsFromLocation:queryString];
}

- (IBAction)dismissLoginScreen:(UIStoryboardSegue*)sender{
    NSLog(@"bye bye");
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"]){
        [self performSegueWithIdentifier:@"firstLogin" sender:self];
    }
    else
    {
    
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)])
        {
            [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound |         UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        }
        else
        {
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        }
        
        if (self.hasBeenChecked != YES){
             [self addressBookAuth];
        }
        
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self.locationManager requestAlwaysAuthorization];
        }
    }
    self.firstTimeChecked = @"Yes";
    
}
- (void)viewDidLoad {

    [super viewDidLoad];
    if(!self.users){
        self.users = [[NSMutableArray alloc] initWithCapacity:10];
    }
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];

    if (self.contactsHasBeenChecked){
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, self.error);
        [self performSelector:@selector(listPeopleInAddressBook:) withObject:(__bridge id)(addressBook) afterDelay:3.0];
    }

 
}

- (void)updateUsers:(NSDictionary *)dict{
    
    NSLog(@"User diction %@", dict);
    NSArray *urls = [dict valueForKey:@"images"];
    [self.users removeAllObjects];

    NSLog(@"URLS From Users Method %@", urls);
    for (NSString *url in urls) {
        User *user = [[User alloc] init];
        user.imageUrl = url;
//        user.name = @"Pete";
        user.phone = @"8132634315";
        [self.users addObject:user];
        [self updateImageDataForUser:user];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


-(NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}


-(NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.users.count;
}

-(UICollectionViewCell*) collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath{

    Cell *aCell = (Cell *)[cv dequeueReusableCellWithReuseIdentifier:@"myCell" forIndexPath:indexPath];
    User *user = (User *)[self.users objectAtIndex:indexPath.row];

//    aCell.layer.borderWidth = 1;
//    aCell.layer.borderColor = [UIColor redColor].CGColor;
    
    aCell.label.text = user.name;
    NSLog(@"Username %@", user.name);
    if (user.image) {
        aCell.image.image = user.image;
        [aCell.image.layer setMasksToBounds:YES];
        [aCell.image.layer setBorderColor:[UIColor whiteColor].CGColor];
        [aCell.image.layer setBorderWidth:1];
        [aCell.image.layer setCornerRadius:35.5];
        [aCell.spinner stopAnimating];
        aCell.image.hidden = NO;
    } else {
        aCell.image.hidden = YES;
//        [aCell.spinner startAnimating];
        aCell.image.image = user.image;
    }
    
    return aCell;
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    User *selectedUser = (User *)[self.users objectAtIndex:indexPath.row];
    NSLog(@"You selected: %@", selectedUser);
    
    [self promptUserToCall:selectedUser.phone];
    
    
}

- (void)promptUserToCall:(NSString *)phoneNumber{
    
    NSURL *phoneUrl = [NSURL URLWithString:[NSString  stringWithFormat:@"telprompt:%@",phoneNumber]];
    
    if ( phoneNumber != nil && [[UIApplication sharedApplication] canOpenURL:phoneUrl]) {
        [[UIApplication sharedApplication] openURL:phoneUrl];
    } else
    {
        [[[UIAlertView alloc] initWithTitle:@"No Phone found" message:@"give them a call" delegate:nil cancelButtonTitle:@"Don't Call" otherButtonTitles:nil] show];
    }
}


// HEADER CODE ///


-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
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
    NSLog(@"FirstTime Checked %@", self.firstTimeChecked);
    if (self.firstTimeChecked == @"Yes")
    {
        self.firstTimeChecked = @"No";
    }
    else
    {
        [NSThread sleepForTimeInterval:2.0f];
    }
    
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
    
    
    
////    / MOVEMENT TOLERANCE
//        if (prevLat == nil){
//            prevLat = &latitude;
//        }
//        else if (prevLat == &latitude){
//            [self.locationManager stopUpdatingLocation];
//        }
//        else if (prevLat != &latitude){
//            [self.locationManager startUpdatingLocation];
//        }
//    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *token = appDelegate.pushCode;
    
    //    NSLog(@"%f", latitude);
    [self makeRequest:[NSString stringWithFormat:@"%f&lon=%f&token=%@",latitude,longitude,token]];
//    [self makeRequest:[NSString stringWithFormat:@"%f&lon=%f&token=%@",latitude,longitude]];
}

- (void)loadURLsFromLocation:(NSString *)locationString {
    if(!self.bgQueue){
        self.bgQueue = [[NSOperationQueue alloc] init]; // Background threads it (backgroundqueue).
    }
    
    [NSThread sleepForTimeInterval:2.0f];

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
                                   [self updateUsers:imagesDict];
                               }
                               
                           }];
}

- (void)updateImageDataForUser:(User *)user{
    
    if(user.image){ return; }
    
    [NSURLConnection sendAsynchronousRequest:
     [NSURLRequest requestWithURL:
      [NSURL URLWithString:user.imageUrl]]
                                       queue:self.bgQueue
                           completionHandler: ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if(data && !connectionError){
                                   user.image = [UIImage imageWithData:data];
                                   [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                       [self.collectionView reloadData];
                                   }];
                               } else {
                                   NSLog(@"%@ - %@", NSStringFromSelector(_cmd), connectionError);
                               }
                           }];
}




// Address Book Methods
-(void)addressBookAuth
{
//    NSLog(@"You are in addressBookAuth");
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
            [self performSelector:@selector(listPeopleInAddressBook:) withObject:(__bridge id)(addressBook) afterDelay:3.0];
        } else {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[[UIAlertView alloc] initWithTitle:nil message:@"This app requires access to your contacts to function properly. Please visit to the \"Privacy\" section in the iPhone Settings app." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            });
            
        }
        
        CFRelease(addressBook);
    });
}



-(void)listPeopleInAddressBook:(ABAddressBookRef *) addressBook {
    
//    NSLog(@"made it to the adress book method send");
    NSArray *allPeople = CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(addressBook));
    NSInteger numberOfPeople = [allPeople count];
    
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
            NSString *key = [NSString stringWithFormat:@"person%ld", (long)i];
            [contactDictionary setObject:thisPerson forKey:key];
        }
    }
    
    
    NSError *err = nil;
    NSData *contactsToServer = [NSJSONSerialization dataWithJSONObject:contactDictionary options:0 error:&err];
    NSLog(@"ERROR - %@", err);

    if(!self.bgQueue){
        self.bgQueue = [[NSOperationQueue alloc] init]; // Background threads it (backgroundqueue).
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"https://whispering-stream-9304.herokuapp.com/contacts"]];
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
}












@end
