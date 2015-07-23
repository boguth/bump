//
//  User.h
//  Bump
//
//  Created by Nick Siefken on 7/23/15.
//  Copyright (c) 2015 Bump Boys!, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface User : NSObject

@property (strong, nonatomic) NSString *imageUrl;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *phone;
//tel:

@end
