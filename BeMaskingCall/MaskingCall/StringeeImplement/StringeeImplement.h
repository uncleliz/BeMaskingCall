//
//  StringeeImplement.h
//  SampleVoiceCall
//
//  Created by Hoang Duoc on 10/25/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Stringee/Stringee.h>
#import "CallManager.h"
#import <Intents/Intents.h>
// Determine which environment we are running in for APNS
# ifdef isRunningInDevModeWithDevProfile
#     define isProductionMode NO
#else
#    define isProductionMode YES
#endif

// Device
#define SCR_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCR_HEIGHT [UIScreen mainScreen].bounds.size.height
#define IS_IPHONE UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone

@interface StringeeImplement : NSObject<StringeeConnectionDelegate, StringeeIncomingCallDelegate, CallManagerDelegate>

@property (strong, nonatomic) StringeeClient *stringeeClient;
@property (assign, nonatomic) SignalingState signalingState;

+ (StringeeImplement *)instance;

- (void)connectToStringeeServer;

- (void)stopRingingWithMessage:(NSString *)message;

- (void)createCallFollowUserActivity:(NSUserActivity *)userActivity;
-(BOOL)isMaskingCall;
-(void)reciverIncomingCallWithStringeeCall:(StringeeCall *)stringeeCall;
-(void)callOutgoingScreen;
-(void)checkOpenCallingVC;
-(void)incomingFromVoipPush;
@end
