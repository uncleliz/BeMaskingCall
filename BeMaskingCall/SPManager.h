//
//  SPManager.h
//  Softphone
//
//  Created by Hoang Duoc on 3/5/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CallKit/CallKit.h>
#import "UserModel.h"
#import "ConfigMaskingCallModel.h"
#import "BeCustomerInfoModel.h"
#import "RideInfoModel.h"
#import "CallingViewController.h"
typedef NS_ENUM(NSInteger, SyncStateCalling) {
    // Chưa có cuộc gọi
    SyncStateCallingNone,
    
    // Đang có cuộc gọi đi
    SyncStateCallingInComing,
    
    // Đang có cuộc gọi đên
    SyncStateCallingOutGoing,
};

@interface SPManager : NSObject

+ (SPManager *)instance;

@property (strong, nonatomic) NSDictionary *allKeys;
@property (strong, nonatomic) NSMutableArray *listKeys;
@property (strong, nonatomic) NSMutableDictionary *dicSections;

@property (strong, nonatomic) NSMutableArray *arrayCallHistories;
@property (strong, nonatomic) CTCallCenter *callCenter;
@property (strong, nonatomic) CXCallObserver NS_AVAILABLE_IOS(10.0) *callObserver;
@property (strong, nonatomic) NSUserActivity *userActivity;

@property (strong, nonatomic) NSString *deviceToken;
@property (assign, nonatomic) BOOL hasRegisteredToReceivePush;
@property (assign, nonatomic) BOOL isPushKit;
@property (strong, nonatomic) NSString *voipToken;
@property (assign, nonatomic) SyncStateCalling isClickOutGoing;

@property (strong, nonatomic) UserModel *myUser;
@property (strong, nonatomic) ConfigMaskingCallModel *configMaskingCall;

@property (strong, nonatomic) BeCustomerInfoModel *customerInfo;
@property (strong, nonatomic) RideInfoModel *rideInfo;

@property (nonatomic, strong) NSString *baseURLString;
@property (nonatomic, strong) NSString *subUrlString;

-(void) getConfigMaskingCall;
- (NSString *)getNumberForCallOut;
- (BOOL)isSystemCall;
- (BOOL)isEnableCallInApp;
-(BOOL)isEnableMaskingCall;
-(int) calTimeOut;
-(NSArray*) maskingNumber;
- (NSString*) getNumberMaskWithTrip:(NSString*)tripID withDriverPhoneNumber:(NSString*)driverPhoneNumber;
- (void)fetchMaskingNumberDriverID:(NSString*)strDriverId  engagementID:(NSString*)engagementID completionHandler:(void(^)(id numberPhone))completionHandler;
- (void) updateConfigMaskingCall:(id) responseObject driverID:(NSString*)strDriverId;
// Instances
@property (strong, nonatomic) CallingViewController *callingViewController;
- (void) connectToStringeeServer;
- (void)stopRingingWithMessage:(NSString *)message;
- (void)createCallFollowUserActivity:(NSUserActivity *)userActivity;
-(BOOL)isMaskingCall;
@end
