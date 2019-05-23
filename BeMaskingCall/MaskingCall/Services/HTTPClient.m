//
//  HTTPClient.m
//  Softphone
//
//  Created by Hoang Duoc on 3/15/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import "HTTPClient.h"

static HTTPClient *httpClient = nil;

@implementation HTTPClient {
   AFHTTPSessionManager * manager;
}

// MARK: - Init
+ (HTTPClient *)instance {
    @synchronized(self) {
        if (httpClient == nil) {
            httpClient = [[self alloc] init];
        }
    }
    return httpClient;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration * configure = [NSURLSessionConfiguration defaultSessionConfiguration];
        configure.timeoutIntervalForRequest = 30;
        manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configure];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", nil];
        [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    }
    return self;
}

- (void)POST:(NSString *)strUrl parameters:(NSDictionary<NSString *, id> *)parameters completionHandler:(void(^)(id responseObject))completionHandler {
    
    NSString *targetUrl = [[self baseURLString] stringByAppendingString:strUrl];

    [manager POST:targetUrl parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary * data = (NSDictionary *)responseObject;
        completionHandler(data);        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // Request thất bại
        completionHandler(error.localizedDescription);
    }];
}
- (void)GET:(NSString *)strUrl parameters:(NSDictionary<NSString *, id> *)parameters completionHandler:(void(^)(id responseObject))completionHandler {
    
    NSString *targetUrl = [[self baseURLString] stringByAppendingString:strUrl];
    [manager GET:targetUrl parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary * data = (NSDictionary *)responseObject;
        completionHandler(data);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // Request thất bại
        completionHandler(error.localizedDescription);
    }];
    
}


@end
