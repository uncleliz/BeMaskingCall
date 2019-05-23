//
//  BeCommon.h
//  BeMaskingCall
//
//  Created by manh.le on 5/23/19.
//  Copyright © 2019 manh.le. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"

@interface BeCommon : NSObject
{
    BOOL wasInternetWorking;
}
+ (nonnull BeCommon *)shareCommonMethods;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL checkInternetConnection;
- (nonnull NSString *)passValidString:(nullable id)passingString;
@end

