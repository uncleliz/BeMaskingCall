//
//  GlobalService.m
//  Softphone
//
//  Created by Hoang Duoc on 3/5/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import "GlobalService.h"
#import "HTTPClient.h"
#import "SPManager.h"
@implementation GlobalService

+ (void)getAccessTokenWithParameters:(NSDictionary *)params completionHandler:(void(^)(id responseObject))completionHandler {
    [HTTPClient instance].baseURLString = [SPManager instance].baseURLString;
    
    [[HTTPClient instance] POST:[NSString stringWithFormat:@"%@/stringee_token",[SPManager instance].subUrlString] parameters:params completionHandler:^(id responseObject) {
            completionHandler(responseObject);
    }];
}
+ (void)getConfigMarkingCallompletionHandler:(void(^)(id responseObject))completionHandler {
    [HTTPClient instance].baseURLString = [SPManager instance].baseURLString;
    [[HTTPClient instance] GET:@"stringee_config" parameters:nil completionHandler:^(id responseObject) {
        completionHandler(responseObject);
    }];
}
+ (void)putTrackingSignalWithParameters:(NSDictionary *)params completionHandler:(void(^)(id responseObject))completionHandler {
    [HTTPClient instance].baseURLString = [SPManager instance].baseURLString;
    [[HTTPClient instance] POST:[NSString stringWithFormat:@"%@/stringee_quality",[SPManager instance].subUrlString] parameters:params completionHandler:^(id responseObject) {
        completionHandler(responseObject);
    }];
}
+ (void)getMaskingNumberWithParameters:(NSDictionary *)params completionHandler:(void(^)(id responseObject))completionHandler {
    [HTTPClient instance].baseURLString = [SPManager instance].baseURLString;
    [[HTTPClient instance] POST:[NSString stringWithFormat:@"%@/stringee_masking_number",[SPManager instance].subUrlString] parameters:params completionHandler:^(id responseObject) {
        completionHandler(responseObject);
    }];
}

@end
