//
//  RideInfoModel.h
//  BeMaskingCall
//
//  Created by manh.le on 5/23/19.
//  Copyright © 2019 manh.le. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RideInfoModel : NSObject
@property(nonatomic, strong) NSString *driverID;
@property(nonatomic, strong) NSString *engagementID;
@property(nonatomic, strong) NSString *driverName;
@property(nonatomic, strong) NSString *driverPhoneNumber;

@end

NS_ASSUME_NONNULL_END
