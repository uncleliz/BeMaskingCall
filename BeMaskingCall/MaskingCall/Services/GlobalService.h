//
//  GlobalService.h
//  Softphone
//
//  Created by Hoang Duoc on 3/5/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GlobalService : NSObject

+ (void)getAccessTokenWithParameters:(NSDictionary *)params completionHandler:(void(^)(id responseObject))completionHandler;
+ (void)getConfigMarkingCallompletionHandler:(void(^)(id responseObject))completionHandler;
+ (void)putTrackingSignalWithParameters:(NSDictionary *)params completionHandler:(void(^)(id responseObject))completionHandler;
+ (void)getMaskingNumberWithParameters:(NSDictionary *)params completionHandler:(void(^)(id responseObject))completionHandler;
@end
