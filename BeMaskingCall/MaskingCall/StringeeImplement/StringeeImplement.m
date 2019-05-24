//
//  StringeeImplement.m
//  SampleVoiceCall
//
//  Created by Hoang Duoc on 10/25/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import "StringeeImplement.h"
#import "SPManager.h"
#import "CallManager.h"
#import "CallingViewController.h"
#import "Utils.h"
#import "GlobalService.h"
#import "BeCommon.h"
@implementation StringeeImplement {
    StringeeCall * seCall;
    BOOL hasAnswered;
    BOOL hasConnected;
    BOOL audioIsActived;
    
    NSTimer *ringingTimer;
    
    UIBackgroundTaskIdentifier backgroundTaskIdentifier;
}

static StringeeImplement *sharedMyManager = nil;

+ (StringeeImplement *)instance {
    @synchronized(self) {
        if (sharedMyManager == nil) {
            sharedMyManager = [[self alloc] init];
        }
    }
    return sharedMyManager;
}

- (id)init {
    self = [super init];
    if (self) {
        // Khởi tạo StringeeClient
        self.stringeeClient = [[StringeeClient alloc] initWithConnectionDelegate:self];
        self.stringeeClient.incomingCallDelegate = self;
        [CallManager sharedInstance].delegate = self;
    }
    return self;
}

// Kết nối tới stringee server
-(void) connectToStringeeServer {
    if ([SPManager instance].myUser.accessToken.length) {
        [self.stringeeClient connectWithAccessToken:[SPManager instance].myUser.accessToken];
    }
    [self getAccessTokenAndConnect:^(BOOL success) {
        
    }];
}

// MARK:- Stringee Connection Delegate

// Lấy access token mới và kết nối lại đến server khi mà token cũ không có hiệu lực
- (void)requestAccessToken:(StringeeClient *)StringeeClient {
    NSLog(@"requestAccessToken");
    [self getAccessTokenAndConnect:^(BOOL success) {
        
    }];
}

- (void)didConnect:(StringeeClient *)stringeeClient isReconnecting:(BOOL)isReconnecting {
    NSLog(@"didConnect");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([SPManager instance].userActivity) {
            [self createCallFollowUserActivity:[SPManager instance].userActivity];
        }
    });
}

- (void)didDisConnect:(StringeeClient *)stringeeClient isReconnecting:(BOOL)isReconnecting {
    NSLog(@"didDisConnect");
}

- (void)didFailWithError:(StringeeClient *)stringeeClient code:(int)code message:(NSString *)message {
    NSLog(@"didFailWithError - %@", message);
}

- (void)didReceiveCustomMessage:(StringeeClient *)stringeeClient message:(NSDictionary *)message fromUserId:(NSString *)userId {
    
}


- (void)incomingCallWithStringeeClient:(StringeeClient *)stringeeClient stringeeCall:(StringeeCall *)stringeeCall {
    [self reciverIncomingCallWithStringeeCall:stringeeCall];
}
-(void)reciverIncomingCallWithStringeeCall:(StringeeCall *)stringeeCall
{
    // disable call in app
    NSString *strAccessToken = [[BeCommon shareCommonMethods] passValidString:[SPManager instance].customerInfo.publicAccessTokenString];
    if ([SPManager instance].isEnableCallInApp == NO  && strAccessToken.length == 0)
    {
//        [stringeeCall rejectWithCompletionHandler:^(BOOL status, int code, NSString *message) {
//            NSLog(@"***** Reject - %@", message);
//        }];
        [self.stringeeClient disconnect];
        return;
    }
    //kiểm tra nếu customer đang gọi đi cho driver, đồng thời driver cũng gọi tới cho customer
    //+ thì sẽ reject cuộc gọi từ phía driver và tiếp tục cuộc gọi từ customer
    //+ ngược lại phía driver sẽ reject cuộc gọi đi và nhận cuộc gọi tới từ customer

    if (![CallManager sharedInstance].currentCall && ![SPManager instance].callingViewController && ![[SPManager instance] isSystemCall] && [SPManager instance].isClickOutGoing == SyncStateCallingNone) {
        [SPManager instance].isClickOutGoing = SyncStateCallingInComing;
        seCall = stringeeCall;
        //        stringeeCall.delegate = self;
        self.signalingState = -1;
        hasAnswered = NO;
        
        if (@available(iOS 10, *)) {
            // Callkit
            BOOL isAppToApp = NO; // Là cuộc gọi giữa 2 ứng dụng chứ ko phải là từ ứng dụng ra số di động hay từ số di động vào ứng dụng
            //            NSString *phoneNumber;
            
            // Xử lý cho trường hợp callkit lưu lịch sử cuộc gọi và khi click vào lịch sử cuộc gọi thì chúng ta cần biết kiểu cuộc gọi
            if (stringeeCall.callType == CallTypeInternalIncomingCall) {
                isAppToApp = YES;
                //                phoneNumber = [@"IC" stringByAppendingString:seCall.from];
            } else {
                //                phoneNumber = [@"EX" stringByAppendingString:seCall.from];
            }
            //            if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
            //                [self openScreenCall:stringeeCall];
            //            }
            //            else
            //            {
            //mld:- hardcode
            NSString *engagementID = @"";
            if ([seCall.from isEqualToString:[SPManager instance].rideInfo.driverID] || [seCall.to isEqualToString:[SPManager instance].rideInfo.driverID]) {
                engagementID = [SPManager instance].rideInfo.engagementID;
            }
            [[CallManager sharedInstance] reportIncomingCallForUUID:[NSUUID new] phoneNumber:seCall.from callerName:seCall.fromAlias isVideoCall:stringeeCall.isVideoCall engagementID:engagementID  completionHandler:^(NSError *error) {
                if (!error) {
                    [self openScreenCall:stringeeCall];
                } else {
                    [SPManager instance].isClickOutGoing = SyncStateCallingNone;
                    [seCall rejectWithCompletionHandler:^(BOOL status, int code, NSString *message) {
                        NSLog(@"***** Reject - %@", message);
                    }];
                }
            }];
            
            //            }
        } else {
            // Local push
            [self beginBackgroundTask];
            
            if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
                [self startRinging];
            }
            [self openScreenCall:stringeeCall];
        }
        
    } else {
        [stringeeCall rejectWithCompletionHandler:^(BOOL status, int code, NSString *message) {
            NSLog(@"***** Reject - %@", message);
        }];
    }
}
// cuoc goi den
-(void)openScreenCall:(StringeeCall *)stringeeCall
{
    NSBundle *localBundle  = [NSBundle bundleForClass:[CallingViewController class]];
    CallingViewController *callingVC = [[CallingViewController alloc] initWithNibName:@"CallingViewController" bundle:localBundle];
    callingVC.isIncomingCall = YES;
    callingVC.username = stringeeCall.fromAlias;
    callingVC.stringeeCall = stringeeCall;
    callingVC.isVideoCall = stringeeCall.isVideoCall;
    [SPManager instance].callingViewController = callingVC;
    [Utils delayCallback:^{
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:callingVC animated:NO completion:nil];
    } forTotalSeconds:0.5];
}
-(void)checkOpenCallingVC
{
    if([CallManager sharedInstance].currentCall && seCall.isIncomingCall)
    {
        if (![SPManager instance].callingViewController) {
            [self openScreenCall:seCall];
        }
        else
        {
            [Utils delayCallback:^{
                [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:[SPManager instance].callingViewController animated:NO completion:nil];
            } forTotalSeconds:0.5];
        }
        [self callDidAnswer];
    }
}
-(void)incomingFromVoipPush
{
    [self reciverIncomingCallWithStringeeCall:seCall];

}
// MARK: - Private Method

- (void)checkAnswerCall {
    if ([SPManager instance].callingViewController.isIncomingCall && hasAnswered && audioIsActived) {
        [[SPManager instance].callingViewController answerCallWithAnimation:NO];
    }
}

- (void)startRinging {
    if (!ringingTimer) {
        ringingTimer = [NSTimer scheduledTimerWithTimeInterval:8.0 target:self selector:@selector(displayRingingNotification) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:ringingTimer forMode:NSRunLoopCommonModes];
        [ringingTimer fire];
    }}

- (void)displayRingingNotification {
    NSString *message = [NSString stringWithFormat:@"%@ Đang gọi...", seCall.from];
    [self displayLocalNotificationWithMessage:message soundName:@"incoming_call.aif"];
}
// push local notification type call
- (void)displayLocalNotificationWithMessage:(NSString *)message soundName:(NSString *)soundName {
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    notification.repeatInterval = 0;
    notification.soundName = soundName;
    [notification setAlertBody:message];
    [notification setFireDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    [notification setTimeZone:[NSTimeZone  defaultTimeZone]];
    
    //    [[UIApplication sharedApplication] setScheduledLocalNotifications:[NSArray arrayWithObject:notification]];
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}



- (void)stopRingingWithMessage:(NSString *)message {
    if (ringingTimer) {
        
        if (message.length) {
            [self displayLocalNotificationWithMessage:message soundName:UILocalNotificationDefaultSoundName];
        }
        
        CFRunLoopStop(CFRunLoopGetCurrent());
        [ringingTimer invalidate];
        ringingTimer = nil;
        
        [self endBackgroundTask];
    }
}

- (void)beginBackgroundTask {
    backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundTask];
    }];
}

- (void)endBackgroundTask {
    [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
    backgroundTaskIdentifier = UIBackgroundTaskInvalid;
}

- (void)getAccessTokenAndConnect:(void(^)(BOOL success))completionHandler {
    /*
    UserModel *user = [[UserModel alloc] init];
    user.phone = @"84353095857";
    user.token = @"cwB387";
    user.expireTime = 1555563322;
    user.accessToken =  @"eyJjdHkiOiJzdHJpbmdlZS1hcGk7dj0xIiwidHlwIjoiSldUIiwiYWxnIjoiSFMyNTYifQ.eyJqdGkiOiJTS0JWeFQxbjVLa3FnbEdjY1Jtc0Q0MEZKUkZsRHZzTEIyLTE1NTU2NDkzNzYiLCJpc3MiOiJTS0JWeFQxbjVLa3FnbEdjY1Jtc0Q0MEZKUkZsRHZzTEIyIiwiZXhwIjoxNTU4MjQxMzc2LCJ1c2VySWQiOiIxMDAwMDAwODM5In0._MdWz5dRg6pJd2OkUBov6M_vlOictLtbtaUzpoCN3-0";
    [SPManager instance].myUser = user;//[[UserModel alloc] initWithData:data];
    [Utils writeCustomObjToUserDefaults:@"myUser" object:[SPManager instance].myUser];
    
    [self.stringeeClient connectWithAccessToken:[SPManager instance].myUser.accessToken];
    */
    long long timeStamp = (long long)[[NSDate date] timeIntervalSince1970];
    NSLog(@"timeStamp %lld", timeStamp);
    NSLog(@"expireTime %lld", [SPManager instance].myUser.expireTime);
    NSString *strUserId = [[BeCommon shareCommonMethods] passValidString:[SPManager instance].customerInfo.userIDString];
    if (![SPManager instance].myUser.accessToken.length || timeStamp > [SPManager instance].myUser.expireTime || strUserId != [SPManager instance].myUser.userID) {
        NSString *strNameCustomer = [[[BeCommon shareCommonMethods] passValidString:[SPManager instance].customerInfo.userNameString] capitalizedString];
        NSString *strPhoneNumber = [[BeCommon shareCommonMethods] passValidString:[SPManager instance].customerInfo.phoneNumberString];
        NSString *strVoipToken = [[BeCommon shareCommonMethods] passValidString:[SPManager instance].voipToken];
        NSString *strAccessToken = [[BeCommon shareCommonMethods] passValidString:[SPManager instance].customerInfo.publicAccessTokenString];
        NSString *strEmail = [[BeCommon shareCommonMethods] passValidString:[SPManager instance].customerInfo.userEmailString];

                NSDictionary *params = @{
                                     @"user_id": strUserId,
                                     @"access_token": strAccessToken,
                                     @"voip_token": strVoipToken,
                                     @"alias": strNameCustomer,
                                     @"phone_number": strPhoneNumber,
                                     @"email": strEmail
                                     };

        [GlobalService getAccessTokenWithParameters:params completionHandler:^(id responseObject) {
            NSLog(@"getAccessTokenAndConnect %@", responseObject);
            BOOL isSuccess = NO;
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                if ([responseObject[@"success"] boolValue] == YES) {
                    isSuccess = TRUE;
                    NSString *strAccessToken = @"";
                    if (responseObject[@"data"]) {
                        strAccessToken = responseObject[@"data"][@"stringee_token"];
                    }
                    long long nextTimeStamp = (long long)[[self nextDate:[NSDate date]] timeIntervalSince1970];
                    UserModel *userModel = [[UserModel alloc] init];
                    userModel.phone = strPhoneNumber;
                    userModel.accessToken = strAccessToken;
                    userModel.expireTime = nextTimeStamp;
                    userModel.userID = strUserId;
                    [SPManager instance].myUser = userModel;
                    //mld: disbale cache myuser
                    [Utils writeCustomObjToUserDefaults:@"myUser" object:[SPManager instance].myUser];
                    
                    [self.stringeeClient connectWithAccessToken:[SPManager instance].myUser.accessToken];
                }
            }
            completionHandler(isSuccess);
//            if (!isSuccess) {
//                [self getAccessTokenAndConnect];
//            }
        }];
     }
    else
    {
        completionHandler(TRUE);
    }
}
-(NSDate*)nextDate:(NSDate*)currentDate
{
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = 1;
    
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    NSDate *nextDate = [theCalendar dateByAddingComponents:dayComponent toDate:currentDate options:0];
    return nextDate;
}
// MARK: - CallManagerDelegate

- (void)callDidAnswer {
    NSLog(@"callDidAnswer");
    hasAnswered = YES;
    [self checkAnswerCall];
}

- (void)callDidEnd {
    NSLog(@"callDidEnd");
    
    if (self.signalingState != SignalingStateBusy && self.signalingState != SignalingStateEnded) {
        if (seCall.isIncomingCall && !hasAnswered) {
            [[SPManager instance].callingViewController decline];
        } else {
            [[SPManager instance].callingViewController.stringeeCall hangupWithCompletionHandler:^(BOOL status, int code, NSString *message) {
                NSLog(@"*****HangupCall %@", message);
                if (!status) {
                    [[SPManager instance].callingViewController endCallAndDismissWithTitle:@"Kết thúc cuộc gọi"];
                }
            }];
        }
    }
    hasAnswered = NO;
}

- (void)callDidHold:(BOOL)isOnHold {
    NSLog(@"callDidHold");
}

- (void)callDidFail:(NSError *)error {
    NSLog(@"callDidFail");
    //    [seCall hangupWithCompletionHandler:^(BOOL status, int code, NSString *message) {
    //        NSLog(@"*****Hangup - %@", message);
    //    }];
    [[SPManager instance].callingViewController endCallAndDismissWithTitle:@"Kết thúc cuộc gọi"];
    
}

- (void)callDidActiveAudioSession {
    NSLog(@"callDidActiveAudioSession");
    audioIsActived = YES;
    [self checkAnswerCall];
}

- (void)callDidDeactiveAudioSession {
    NSLog(@"callDidDeactiveAudioSession");
    audioIsActived = NO;
}

- (void)muteTapped:(CXSetMutedCallAction *)action NS_AVAILABLE_IOS(10.0) {
    NSLog(@"muteTapped");
    if (@available(iOS 10, *)) {
        [[SPManager instance].callingViewController mute];
    }
}

- (void)createCallFollowUserActivity:(NSUserActivity *)userActivity {
    if ([SPManager instance].isEnableCallInApp && [StringeeImplement instance].stringeeClient.hasConnected) {
        if (@available(iOS 10, *)) {
            // Lấy thông tin cuộc gọi
            INInteraction *interaction = userActivity.interaction;
            INIntent *intent = interaction.intent;
            BOOL isVideoCall = NO;
            NSString *to;
            if ([intent isKindOfClass:[INStartAudioCallIntent class]]) {
                NSLog(@"AUDIO %@", ((INStartAudioCallIntent *)intent).contacts.firstObject.personHandle.value);
                to = ((INStartAudioCallIntent *)intent).contacts.firstObject.personHandle.value;
            } else if ([intent isKindOfClass:[INStartVideoCallIntent class]]) {
                NSLog(@"VIDEO %@", ((INStartAudioCallIntent *)intent).contacts.firstObject.personHandle.value);
                to = ((INStartAudioCallIntent *)intent).contacts.firstObject.personHandle.value;
                isVideoCall = YES;
            }
            [self createCallToNumber:to isVideoCall:isVideoCall isCallout:NO];
        }
    }
    /*
    else
    {
        NSString *strDriverPhoneNumber = [[SPManager instance] getNumberMaskWithTrip:[FindDriverManager handleDriverManager].rideInfoDictionary.engagementID withDriverPhoneNumber:@"driver_phone"];
        NSURL *phoneUrl = [NSURL URLWithString:[NSString  stringWithFormat:@"telprompt:%@",strDriverPhoneNumber]];
        if ([[UIApplication sharedApplication] canOpenURL:phoneUrl]) {
            [[UIApplication sharedApplication] openURL:phoneUrl];
        } else {
            [[CommonFunctions shareCommonMethods] showCustomAlertViewFromCommonWithTitle:nil message:[ApplicationStrings Call_Facility_Unavailable] withButtonTitle:[ApplicationStrings ok]];
        }
    }
     */
    
    [SPManager instance].userActivity = nil;
}
// cuoc goi di tu history
- (void)createCallToNumber:(NSString *)to isVideoCall:(BOOL)isVideoCall isCallout:(BOOL)isCallout{
    if (![[SPManager instance] isSystemCall] && to.length && ![SPManager instance].callingViewController && [[BeCommon shareCommonMethods] checkInternetConnection] && [SPManager instance].isEnableCallInApp) {
       NSDictionary *dicDecode = [[CallManager sharedInstance] decodeWithTokenCallKit:to];
        NSString *toNumber = (NSString*)dicDecode[@"callnumber"]; //[[CallManager sharedInstance] getPhoneNumberWithTokenCallKit:to];
        NSString *callName = (NSString*)dicDecode[@"callname"];//[[CallManager sharedInstance] getCallNamerWithTokenCallKit:to];
        NSString *engagementID = (NSString*)dicDecode[@"engagementid"];
        NSBundle *localBundle  = [NSBundle bundleForClass:[CallingViewController class]];

        CallingViewController *callingVC = [[CallingViewController alloc] initWithNibName:@"CallingViewController" bundle:localBundle];
        callingVC.isIncomingCall = NO;
        callingVC.username = callName;
        if (isCallout) {
            callingVC.from = [[SPManager instance] getNumberForCallOut];
        } else {
            callingVC.from = [StringeeImplement instance].stringeeClient.userId;
        }
        callingVC.isAppToApp = !isCallout;
        callingVC.to = toNumber;
        callingVC.isVideoCall = isVideoCall;
        callingVC.engagementID = engagementID;
        [SPManager instance].callingViewController = callingVC;
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:callingVC animated:YES completion:nil];
    } else {
//        [Utils showToastWithString:@"Đang diễn ra cuộc gọi hệ thống" withView:[[SPManager instance].contactViewController view]];
    }
}

-(BOOL)isMaskingCall
{
    // deep request option masking call
    [[SPManager instance] getConfigMaskingCall];
    if ([SPManager instance].isEnableCallInApp == NO)
    {
        return NO;
    }
    // kiểm tra nếu cho phép CallInApp nhưng lại mất mạng
    if (![[BeCommon shareCommonMethods] checkInternetConnection]) {
        [self showCustomAlertViewTimeout];
        return TRUE;
    }
    // neu stringeeClient chua co ket noi -> ket noi
    if (![StringeeImplement instance].stringeeClient) {
        [[StringeeImplement instance] connectToStringeeServer];
    }
    if ([StringeeImplement instance].stringeeClient.hasConnected /* && ![[SPManager instance] isSystemCall]*/) {
        long long timeStamp = (long long)[[NSDate date] timeIntervalSince1970];
        NSString *strUserId = [[BeCommon shareCommonMethods] passValidString:[SPManager instance].customerInfo.userIDString];
        if (![SPManager instance].myUser.accessToken.length || timeStamp > [SPManager instance].myUser.expireTime || strUserId != [SPManager instance].myUser.userID) {
            [self getAccessTokenAndConnect:^(BOOL success) {
                if (success == YES) {
                    [self callOutgoingScreen];
                }
            }];
        }
        else
        {
            [self callOutgoingScreen];
        }
        return YES;
    }
    else
    {
        return NO;
    }
}
// cuoc goi di tu trong app
-(void)callOutgoingScreen
{
    if ([SPManager instance].isClickOutGoing == SyncStateCallingNone) {
    [SPManager instance].isClickOutGoing = SyncStateCallingOutGoing;
    
    NSString *driverNameString = [[BeCommon shareCommonMethods] passValidString:[SPManager instance].rideInfo.driverName];
    NSString *driverIDString = [[BeCommon shareCommonMethods] passValidString:[SPManager instance].rideInfo.driverID];
        NSBundle *localBundle  = [NSBundle bundleForClass:[CallingViewController class]];
    CallingViewController *callingVC = [[CallingViewController alloc] initWithNibName:@"CallingViewController" bundle:localBundle];
    callingVC.isIncomingCall = NO;
    callingVC.username = driverNameString;
    callingVC.from = [StringeeImplement instance].stringeeClient.userId; //[[SPManager instance] getNumberForCallOut];
    callingVC.to = driverIDString;
    callingVC.isAppToApp = TRUE;
    callingVC.isVideoCall = NO;
    callingVC.engagementID = [SPManager instance].rideInfo.engagementID;
    [SPManager instance].callingViewController = callingVC;
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:callingVC animated:YES completion:nil];
    }
}
//MARK: - show alert when timeout
- (void)showCustomAlertViewTimeout {
    /*
        SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"" andMessage:@"Cuộc gọi miễn phí không thể thực hiện do vấn đề kết nối mạng từ người nhận. Chuyển sang cuộc gọi thông thường"];
        [alertView setMessageColor:[AppColors themeBlackColor]];
        [alertView addButtonWithTitle:@"Huỷ bỏ"
                                 type:SIAlertViewButtonTypeCancel
                              handler:^(SIAlertView *alertView) {
                                  NSLog(@"Cancel Clicked");
                              }];
        [alertView addButtonWithTitle:@"Đồng ý"
                                 type:SIAlertViewButtonTypeCancel
                              handler:^(SIAlertView *alertView) {
                                  NSLog(@"Ok Clicked");
                                  [Utils delayCallback:^{
                                      [self callDriverPhoneNumber];
                                  } forTotalSeconds:0.5];
                              }];
        
        alertView.transitionStyle = SIAlertViewTransitionStyleFade;
        [alertView show];
     */
}
-(void)callDriverPhoneNumber
{
    /*
        if ([NSString stringWithFormat:@"%@",[FindDriverManager handleDriverManager].rideInfoDictionary.rideInProgress].length != 0) {
            //1. In case masking feature is ON: The app calls OS default dialer and auto fill masking phone number. => after that users can make a phone to phone call
            //2. In case masking feature is OFF/Unknown: The app calls OS default dialer and auto fill driver phone number. => after that users can make a phone to phone call
            NSString *strDriverPhoneNumber = [[SPManager instance] getNumberMaskWithTrip:[FindDriverManager handleDriverManager].rideInfoDictionary.engagementID withDriverPhoneNumber:[FindDriverManager handleDriverManager].rideInfoDictionary.driverPhoneNumber];
            NSURL *phoneUrl = [NSURL URLWithString:[NSString  stringWithFormat:@"telprompt:%@",strDriverPhoneNumber]];
            if ([[UIApplication sharedApplication] canOpenURL:phoneUrl]) {
                //            NSString *logEventString = @"Call to driver made when not arrived";
                //[[CommonFunctions shareCommonMethods] googleAnalyticsWithEventName:logEventString];
                [[UIApplication sharedApplication] openURL:phoneUrl];
                [[EventTrackingManager shared] pushEventWithEventName:@"ride_details_tap_on_call" params:@{
                                                                                                           @"ETA": [[NSUserDefaults standardUserDefaults] integerForKey:USER_RIDE_STATUS] == userRideStateDriverAcceptedRequest ? [FindDriverManager handleDriverManager].rideInfoDictionary.driverUpcomingTime : [FindDriverManager handleDriverManager].rideInfoDictionary.rideTime,
                                                                                                           @"vehicle_type": ([FindDriverManager handleDriverManager].selectedVehicleType == VEEP_VEHICAL_TYPE_TWO_WHEEL_CARRY_PEOPLE ? @"bike": ([FindDriverManager handleDriverManager].selectedVehicleType == VEEP_VEHICAL_TYPE_FOUR_SEATS ? @"4seat_car" : @"7seat_car"))
                                                                                                           } type:EventTrackerTypeGgAnalytics];
            } else {
                [[CommonFunctions shareCommonMethods] showCustomAlertViewFromCommonWithTitle:nil message:[ApplicationStrings Call_Facility_Unavailable] withButtonTitle:[ApplicationStrings ok]];
            }
        }
     */
}
@end
