//
//  SPCallingViewController.h
//  Softphone
//
//  Created by Hoang Duoc on 7/11/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AFNetworking/AFNetworking.h>
@class StringeeCall;
typedef NS_ENUM(NSInteger, ScreenMode) {
    // Cuộc gọi voice đi
    ScreenModeOutgoingVoiceCall,
    
    // Cuộc gọi video đi
    ScreenModeOutgoingVideoCall,
    
    // Cuộc gọi voice đến
    ScreenModeIncomingVoiceCall,
    
    // Cuộc gọi video đến
    ScreenModeIncomingVideoCall,
    
    // Đang gọi voice
    ScreenModeVoiceCall,
    
    // Đang gọi video
    ScreenModeVideoCall,
    
    // Màn hình khi gửi yêu cầu video đi
    ScreenModeRequestVideo,
    
    // Màn hình khi nhận được yêu cầu video
    ScreenModeReplyRequest
};

@interface CallingViewController : UIViewController

// Variable
@property (weak, nonatomic) IBOutlet UILabel *labelPhoneNumber;
@property (weak, nonatomic) IBOutlet UILabel *labelConnecting;
@property (weak, nonatomic) IBOutlet UILabel *labelUsername;
@property (weak, nonatomic) IBOutlet UIButton *buttonMute;
@property (weak, nonatomic) IBOutlet UIButton *buttonSpeaker;
@property (weak, nonatomic) IBOutlet UIView *blurView;
@property (weak, nonatomic) IBOutlet UIButton *buttonEndCall;
@property (weak, nonatomic) IBOutlet UIButton *buttonDecline;
@property (weak, nonatomic) IBOutlet UIButton *buttonAccept;
@property (weak, nonatomic) IBOutlet UILabel *labelMute;
@property (weak, nonatomic) IBOutlet UILabel *labelSpeaker;
@property (weak, nonatomic) IBOutlet UIImageView *imageInternetQuality;
@property (weak, nonatomic) IBOutlet UIButton *buttonCallPad;
@property (weak, nonatomic) IBOutlet UILabel *labelCallPad;
@property (weak, nonatomic) IBOutlet UIView *optionView;
@property (weak, nonatomic) IBOutlet UIView *voiceCallInfoView;
@property (weak, nonatomic) IBOutlet UIView *videoCallInfoView;
@property (weak, nonatomic) IBOutlet UIImageView *imageInternetQualityVC;
@property (weak, nonatomic) IBOutlet UILabel *lbUserNameVC;
@property (weak, nonatomic) IBOutlet UILabel *lbConnectingVC;
@property (weak, nonatomic) IBOutlet UIButton *btSwitchVideo;
@property (weak, nonatomic) IBOutlet UIView *localView;
@property (weak, nonatomic) IBOutlet UIView *remoteView;
@property (weak, nonatomic) IBOutlet UIView *videoBlurView;
@property (weak, nonatomic) IBOutlet UIButton *btCamera;
@property (weak, nonatomic) IBOutlet UILabel *lbRequestVideo;
@property (weak, nonatomic) IBOutlet UIImageView *imgBackground;
@property (weak, nonatomic) IBOutlet UILabel *lbTitle;

@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *from;
@property (strong, nonatomic) NSString *to;
@property (strong, nonatomic) StringeeCall *stringeeCall;
@property (assign, nonatomic) BOOL isIncomingCall;
@property (assign, nonatomic) BOOL isCalling;
@property (assign, nonatomic) BOOL isAppToApp;
@property (assign, nonatomic) BOOL isVideoCall;
@property (assign, nonatomic) ScreenMode screenMode;
@property (strong, nonatomic) NSString *engagementID;

// Action
- (IBAction)endCallTapped:(UIButton *)sender;
- (IBAction)muteTapped:(UIButton *)sender;
- (IBAction)speakerTapped:(UIButton *)sender;
- (IBAction)acceptTapped:(UIButton *)sender;
- (IBAction)declineTapped:(UIButton *)sender;
- (IBAction)callpadTapped:(UIButton *)sender;
- (IBAction)switchVideoTapped:(UIButton *)sender;
- (IBAction)cameraTapped:(UIButton *)sender;

- (void)stopTimer;
- (void)startTimer;
- (void)answerCallWithAnimation:(BOOL)isAnimation;
- (void)decline;
- (void)endCallAndDismissWithTitle:(NSString *)title;
- (void)mute;

-(void) resetCalling;
@end
