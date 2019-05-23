//
//  BeCustomerInfoModel.h
//  BeMaskingCall
//
//  Created by manh.le on 5/23/19.
//  Copyright © 2019 manh.le. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BeCustomerInfoModel : NSObject
@property(nonatomic, strong) NSString *userIDString;
@property(nonatomic, strong) NSString *userNameString;
@property(nonatomic, strong) NSString *userEmailString;
@property(nonatomic, strong) NSString *phoneNumberString;
@property(nonatomic, strong) NSString *publicAccessTokenString;

@end
