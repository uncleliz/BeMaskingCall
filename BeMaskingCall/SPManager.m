//
//  SPManager.m
//  Softphone
//
//  Created by Hoang Duoc on 3/5/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import "SPManager.h"
#import "Utils.h"
#import "GlobalService.h"
#import "StringeeImplement.h"
#import "BeCommon.h"
#define BE_HOTLINE @"1900232345"
#define kmasking_phone_number       @"masking_phone_number"

@implementation SPManager

static SPManager *spManager = nil;

// MARK: - Init
+ (SPManager *)instance {
    @synchronized(self) {
        if (spManager == nil) {
            spManager = [[self alloc] init];
        }
    }
    return spManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Lắng nghe sự kiện terminate app
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveCallHistories) name:UIApplicationWillTerminateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveCallHistories) name:UIApplicationWillResignActiveNotification object:nil];
        
        _listKeys = [[NSMutableArray alloc] init];
        _dicSections = [[NSMutableDictionary alloc] init];
        _allKeys = @{
                    @"A" : @"A",
                    @"B" : @"B",
                    @"C" : @"C",
                    @"D" : @"D",
                    @"E" : @"E",
                    @"F" : @"F",
                    @"G" : @"G",
                    @"H" : @"H",
                    @"I" : @"I",
                    @"J" : @"J",
                    @"K" : @"K",
                    @"L" : @"L",
                    @"M" : @"M",
                    @"N" : @"N",
                    @"O" : @"O",
                    @"P" : @"P",
                    @"Q" : @"Q",
                    @"R" : @"R",
                    @"S" : @"S",
                    @"T" : @"T",
                    @"U" : @"U",
                    @"V" : @"V",
                    @"X" : @"X",
                    @"Y" : @"Y",
                    @"Z" : @"Z",
                    @"W" : @"W"
                    };
        _callingModel =[[CallingVCModel alloc] init];
        //mld: disbale cache myuser
        _myUser = (UserModel *)[Utils readCustomObjFromUserDefaults:@"myUser"];
//        _configMaskingCall = (ConfigMaskingCallModel *)[Utils readCustomObjFromUserDefaults:@"ConfigMaskingCall"];

        if (@available(iOS 10.0, *)) {
            _callObserver = [[CXCallObserver alloc] init];
        } else {
            _callCenter = [[CTCallCenter alloc] init];
        }
        
        _deviceToken = @"";
        _hasRegisteredToReceivePush = NO;
    }
    return self;
}

- (NSString *)getNumberForCallOut {
    NSString *number = @"";
    
    for (CalloutNumberModel *calloutNumber in _myUser.calloutNumbers) {
        if (calloutNumber.phone.length && calloutNumber.isEnable) {
            number = calloutNumber.phone;
            break;
        }
    }
    
    return number;
}

- (void)saveCallHistories {
    [Utils writeCustomObjToUserDefaults:@"call_history" object:_arrayCallHistories];
}

- (BOOL)isSystemCall {
    BOOL isSystemCall = NO;
    if (@available(iOS 10, *)) {
        if (_callObserver.calls.count) {
            isSystemCall = YES;
        }
    } else {
        if (_callCenter.currentCalls.count) {
            isSystemCall = YES;
        }
    }
    
    return isSystemCall;
}
- (BOOL)isEnableCallInApp
{
    BOOL enableCallInApp = [[Utils readCustomObjFromUserDefaults:@"enable_call_in_app"] boolValue];
    return enableCallInApp;
}
-(BOOL)isEnableMaskingCall
{
    BOOL enableMaskingCall = [[Utils readCustomObjFromUserDefaults:@"enable_masking_call"] boolValue];
    
    return enableMaskingCall;
}
-(int) calTimeOut
{
    int callTimeOut = [[Utils readCustomObjFromUserDefaults:@"call_timeout"] intValue];
    return callTimeOut;
}

-(NSArray*) maskingNumber
{
    NSArray *maskingNumber = [Utils readCustomObjFromUserDefaults:@"masking_numbers"];
    return maskingNumber;
}

-(void) getConfigMaskingCall
{
    /*
    //Config duoc tra ve trong RideInfoDictionary
    [GlobalService getConfigMarkingCallompletionHandler:^(id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
//            ConfigMaskingCallModel *configModel = [[ConfigMaskingCallModel alloc] initWithData:responseObject];
//            [SPManager instance].configMaskingCall = configModel;
            //enable call in app
            BOOL enableCallInApp = (responseObject[@"enable_call_in_app"] != nil && responseObject[@"enable_call_in_app"] != [NSNull null]) ? [responseObject[@"enable_call_in_app"] boolValue] : NO;
            [Utils writeCustomObjToUserDefaults:@"enable_call_in_app" object:@(enableCallInApp)];
            
            //enable masking call
            BOOL enableMaskingCall = (responseObject[@"enable_masking_call"] != nil && responseObject[@"enable_masking_call"] != [NSNull null]) ? [responseObject[@"enable_masking_call"] boolValue] : NO;
            [Utils writeCustomObjToUserDefaults:@"enable_masking_call" object:@(enableMaskingCall)];

            //call timout
            int callTimeOut = (responseObject[@"call_timeout"] != nil && responseObject[@"call_timeout"] != [NSNull null]) ? [responseObject[@"call_timeout"] intValue] : 0;
            [Utils writeCustomObjToUserDefaults:@"call_timeout" object:@(callTimeOut)];
            //masking number
            NSArray *phones = (responseObject[@"masking_numbers"] != nil && responseObject[@"masking_numbers"] != [NSNull null]) ? responseObject[@"masking_numbers"] : [[NSArray alloc] init];
            [Utils writeCustomObjToUserDefaults:@"masking_numbers" object:phones];

            if(enableCallInApp)
            {
                [[StringeeImplement instance] connectToStringeeServer];
            }

        }
    }];
     */
}
//
/** 1. Neu Khong co TripID -> tra ve number la nil
    2. Kiem tra trong list masking_number_trip
    2.a. Neu da trip da duoc luu -> tra ve so dien thoai
    2.b. Neu tripid chua duoc luu -> la 1 so
 */
- (NSString*) getNumberMaskWithTrip:(NSString*)tripID withDriverPhoneNumber:(NSString*)driverPhoneNumber
{
    NSString *strNumber = driverPhoneNumber;
    if ([[SPManager instance] isEnableMaskingCall] == YES) {
        if (tripID == nil || tripID.length == 0) {
            return strNumber;
        }
        NSDictionary *dicMaskingInfo = (NSDictionary*)[Utils readCustomObjFromUserDefaults:kmasking_phone_number];
        NSString *strNumberMasking;
        if (dicMaskingInfo) {
            strNumberMasking = (NSString*)dicMaskingInfo[@"phone_number"];
        }

        if (strNumberMasking.length > 0) {
            strNumber = strNumberMasking;
        }
        /*
        NSArray *maskingNumber = [self maskingNumber];
        NSArray *arrMaskTrip = [Utils readCustomObjFromUserDefaults:@"masking_number_trip"];
        
        NSMutableArray *arrTmp = [NSMutableArray new];
        if (arrMaskTrip) {
            [arrTmp addObjectsFromArray:arrMaskTrip];
        }
        
        if (arrTmp.count > 0) {
            //kiem tra neu tripid da duoc store thi lay ra so mask
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"trip contains[c] %@", tripID];
            NSArray *result =[arrTmp filteredArrayUsingPredicate:predicate];
            if (result.count > 0) {
                NSDictionary *dicTmp = result[0];
                strNumber = (NSString*)dicTmp[@"mask_number"];
            }
            //neu chua duo store thi duyet tim 1 so moi chua trung trong store
            else
            {
                //Tim so chua ton tai trong mask_number_trip
                NSString *strFindNumber;
                for (int i = 0; i < maskingNumber.count; i++) {
                    NSString *itemNumber = (NSString*)maskingNumber[i];
                    // check number exist
                    NSPredicate *num_predicate = [NSPredicate predicateWithFormat:@"mask_number contains[c] %@", itemNumber];
                    NSArray *num_result =[arrTmp filteredArrayUsingPredicate:num_predicate];
                    // neu chua luu number
                    if (num_result.count == 0) {
                        strFindNumber = itemNumber;
                        break;
                    }
                }
                
                if (arrTmp.count == 3) {
                    // neu ca 3 so deu trung nhau, thi lay  so o trip 0
                    if (strFindNumber.length == 0) {
                        NSDictionary *dicTmp = arrTmp[0];
                        strNumber = (NSString*)dicTmp[@"mask_number"];
                    }
                    else
                    {
                        strNumber = strFindNumber;
                    }
                    //remove trip 1, add trip 4
                    [arrTmp removeObjectAtIndex:0];
                    [arrTmp addObject:@{@"trip": tripID,@"mask_number": strNumber}];
                }
                else
                {
                    if (strFindNumber.length > 0) {
                        strNumber = strFindNumber;
                        [arrTmp addObject:@{@"trip": tripID,@"mask_number": strNumber}];
                    }
                }
            }
        }
        else
        {
            if (maskingNumber.count > 0) {
                strNumber = (NSString*)maskingNumber[0];
                //save inton list masking number trip
                [arrTmp addObject:@{@"trip": tripID,@"mask_number": strNumber}];
            }
        }
        [Utils writeCustomObjToUserDefaults:@"masking_number_trip" object:arrTmp];
         */
    }
    //check "+"
    if(![strNumber hasPrefix:@"+"] && strNumber.length > 0) {
        strNumber = [NSString stringWithFormat:@"+%@",strNumber];
    }
    return strNumber;
}
-(NSString*) findNumberWithUserId:(NSString*)UserId dataHistory:(NSArray*)dataHistory
{
    NSString *strNumber;
    for (int i = 0; i < dataHistory.count; i++) {
        NSDictionary *dicItem = dataHistory[i];
        if ([UserId isEqualToString:dicItem[@"driver_id"]]) {
            strNumber = [self getNumberMaskWithTrip:dicItem[@"engagement_id"] withDriverPhoneNumber:nil];
        }
    }
    if (strNumber.length == 0) {
        strNumber = BE_HOTLINE;
    }
    return strNumber;
}
- (void)fetchMaskingNumberDriverID:(NSString*)strDriverId  engagementID:(NSString*)engagementID completionHandler:(void(^)(id numberPhone))completionHandler{
    NSDictionary *dicMaskingInfo = (NSDictionary*)[Utils readCustomObjFromUserDefaults:kmasking_phone_number];
    if (dicMaskingInfo) {
        //check if have masking number
        if ([engagementID isEqualToString:dicMaskingInfo[@"engagement_id"]] && engagementID.length > 0) {
            return;
        }
    }
    [Utils removeCustomObjFromUserDefaults:kmasking_phone_number];
    if ([[BeCommon shareCommonMethods] checkInternetConnection]) {
//        __weak SPManager *weakself = self;
        NSString *strUserId = [[BeCommon shareCommonMethods] passValidString:[SPManager instance].customerInfo.userIDString];
        NSString *strAccessToken = [[BeCommon shareCommonMethods] passValidString:[SPManager instance].customerInfo.publicAccessTokenString];
        NSDictionary *params = @{@"from_user_id":strUserId,
                                 @"to_user_id":strDriverId,
                                 @"access_token": strAccessToken,
                                 @"engagement_id":engagementID
                                                       };
        [GlobalService getMaskingNumberWithParameters:params completionHandler:^(id responseObject) {
            if (responseObject) {
                //enable call in app
                BOOL enableCallInApp = (responseObject[@"enable_call_in_app"] != nil && responseObject[@"enable_call_in_app"] != [NSNull null]) ? [responseObject[@"enable_call_in_app"] boolValue] : NO;
                [Utils writeCustomObjToUserDefaults:@"enable_call_in_app" object:@(enableCallInApp)];
                
                //enable masking call
                BOOL enableMaskingCall = (responseObject[@"enable_masking_call"] != nil && responseObject[@"enable_masking_call"] != [NSNull null]) ? [responseObject[@"enable_masking_call"] boolValue] : NO;
                [Utils writeCustomObjToUserDefaults:@"enable_masking_call" object:@(enableMaskingCall)];
                
                //call timout
                int callTimeOut = (responseObject[@"call_timeout"] != nil && responseObject[@"call_timeout"] != [NSNull null]) ? [responseObject[@"call_timeout"] intValue] : 0;
                [Utils writeCustomObjToUserDefaults:@"call_timeout" object:@(callTimeOut)];
                
                if(enableCallInApp)
                {
                    [[StringeeImplement instance] connectToStringeeServer];
                }
            }
            if (responseObject[@"phone_number"])
            {
                NSDictionary *dicMaskingInfo = @{@"driver": strDriverId,@"phone_number":responseObject[@"phone_number"],@"engagement_id": engagementID};
                [Utils writeCustomObjToUserDefaults:kmasking_phone_number object:dicMaskingInfo];
                NSString *phone_number = [[BeCommon shareCommonMethods] passValidString:responseObject[@"phone_number"]];
                completionHandler(phone_number);
            }
            else
            {
                completionHandler(nil);
            }

        }];
    }
    else {
        completionHandler(nil);
    }
}
- (void) updateConfigMaskingCall:(id) responseObject driverID:(NSString*)strDriverId
{
    if (responseObject) {
        //enable call in app
        BOOL enableCallInApp = (responseObject[@"enable_call_in_app"] != nil && responseObject[@"enable_call_in_app"] != [NSNull null]) ? [responseObject[@"enable_call_in_app"] boolValue] : NO;
        [Utils writeCustomObjToUserDefaults:@"enable_call_in_app" object:@(enableCallInApp)];
        
        //enable masking call
        BOOL enableMaskingCall = (responseObject[@"enable_masking_call"] != nil && responseObject[@"enable_masking_call"] != [NSNull null]) ? [responseObject[@"enable_masking_call"] boolValue] : NO;
        [Utils writeCustomObjToUserDefaults:@"enable_masking_call" object:@(enableMaskingCall)];
        
        //call timout
        int callTimeOut = (responseObject[@"call_timeout"] != nil && responseObject[@"call_timeout"] != [NSNull null]) ? [responseObject[@"call_timeout"] intValue] : 0;
        [Utils writeCustomObjToUserDefaults:@"call_timeout" object:@(callTimeOut)];
        
        if(enableCallInApp)
        {
            [[StringeeImplement instance] connectToStringeeServer];
        }
    }
    if (responseObject[@"phone_number"])
    {
        NSDictionary *dicMaskingInfo = @{@"driver": strDriverId,@"phone_number":responseObject[@"phone_number"]};
        [Utils writeCustomObjToUserDefaults:kmasking_phone_number object:dicMaskingInfo];
    }
}
//MARK: - StringeeImplement
// Kết nối tới stringee server
- (void) connectToStringeeServer {
    [[StringeeImplement instance] connectToStringeeServer];
}
- (void)stopRingingWithMessage:(NSString *)message {
    [[StringeeImplement instance] stopRingingWithMessage:message];
}
- (void)createCallFollowUserActivity:(NSUserActivity *)userActivity {
    [[StringeeImplement instance] createCallFollowUserActivity:userActivity];
}
-(BOOL)isMaskingCall
{
    return [[StringeeImplement instance] isMaskingCall];
}
-(void)checkOpenCallingVC
{
    [[StringeeImplement instance] checkOpenCallingVC];

}
@end
