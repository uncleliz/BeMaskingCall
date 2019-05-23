//
//  BeCommon.m
//  BeMaskingCall
//
//  Created by manh.le on 5/23/19.
//  Copyright © 2019 manh.le. All rights reserved.
//

#import "BeCommon.h"
@implementation BeCommon
static BeCommon *shared = NULL;

+ (BeCommon *)shareCommonMethods {
    if (nil != shared)  {
        return shared;
    }
    static dispatch_once_t pred;        // Lock
    dispatch_once(&pred, ^{             // This code is called at most once per app
        shared = [[BeCommon alloc] init];
        
    });
    
    return shared;
}
- (BOOL)checkInternetConnection {
    Reachability *reach = [Reachability reachabilityForInternetConnection];
    NetworkStatus netStatus = [reach currentReachabilityStatus];
    if (netStatus == NotReachable) {
        wasInternetWorking = NO;
        return NO;
    } else {
        wasInternetWorking = YES;
        return YES;
    }
}
- (NSString *)passValidString:(id)passingString {
    if (passingString) {
        return [NSString stringWithFormat:@"%@", passingString];
    } else {
        return @"";
    }
}
@end
