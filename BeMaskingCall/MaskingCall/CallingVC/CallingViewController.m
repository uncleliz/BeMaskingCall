//
//  SPCallingViewController.m
//  Softphone
//
//  Created by Hoang Duoc on 7/11/17.
//  Copyright © 2017 Hoang Duoc. All rights reserved.
//

#import "CallingViewController.h"
#import "StringeeImplement.h"
#import "SPManager.h"
#import "Utils.h"
#import "GlobalService.h"
#import "BeCommon.h"
#import <Stringee/Stringee.h>
static int TIME_WINDOW = 2;
static int CALL_TIME_OUT = 15; // giây

@interface CallingViewController () <StringeeCallDelegate, StringeeRemoteViewDelegate>

@end

@implementation CallingViewController {
    NSTimer *timer;
    NSTimer *reportTimer;
    int timeSec;
    int timeMin;
    AVAudioPlayer *ringAudioPlayer;
    BOOL isMute;
    BOOL isSpeaker;
    
    // Stats report
    long long audioBw;
    double audioPLRatio;
    long long prevAudioPacketLost;
    long long prevAudioPacketReceived;
    double prevAudioTimeStamp;
    long long prevAudioBytes;
    NSMutableArray *arrAudioBw;

    BOOL isDecline;
    BOOL hasCreatedCall;
    BOOL hasAnsweredCall;
    BOOL hasConnectedMedia;
    
    NSTimer *timeoutTimer;
    int interval;
    
    BOOL isShowOption;
    BOOL isEnableLocalVideo;
    
    BOOL hasAcceptedVideo;
//    PulsingAnimationCall *pulsingCall;
    BOOL isAnablePulsing;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //use pulsing
    [self setuPulsing];
    [SPManager instance].callingViewController = self;
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    isShowOption = YES;

    [self.videoCallInfoView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.4]];
    [self.videoBlurView setBackgroundColor:[[UIColor lightGrayColor] colorWithAlphaComponent:0.7]];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tapGesture];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSessionRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (!hasCreatedCall) {
        hasCreatedCall = !hasCreatedCall;
        
        if (_isVideoCall) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
            isEnableLocalVideo = YES;
            
            [[StringeeAudioManager instance] setLoudspeaker:YES];
            isSpeaker = YES;
            
            [self.btCamera setBackgroundImage:[UIImage imageNamed:@"video_enable"] forState:UIControlStateNormal];
        } else {
            [self.btCamera setBackgroundImage:[UIImage imageNamed:@"video_disable"] forState:UIControlStateNormal];
        }
        
        self.localView.frame = CGRectMake(0, 0, SCR_WIDTH, SCR_HEIGHT);
        
        // Bắt đầu check timeout cho cuộc gọi
        timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(checkCallTimeOut) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:timeoutTimer forMode:NSDefaultRunLoopMode];
    
        self.labelUsername.text = self.username;
        self.lbUserNameVC.text = self.username;
        
        [self updateScreenWithScreenMode:-1];
        
        if (self.isIncomingCall) {
            
            if (!self.isCalling) {
                [self startSound];
            }
            
            self.labelPhoneNumber.text = [NSString stringWithFormat:@"Mobile: +%@", self.stringeeCall.from];
            self.stringeeCall.delegate = self;
            [self.stringeeCall initAnswerCall];
        } else {
            
            self.labelPhoneNumber.text = [NSString stringWithFormat:@"Mobile: +%@", self.to];
            
            NSString *fromOfCall;
            if (_isAppToApp) {
                fromOfCall = [StringeeImplement instance].stringeeClient.userId;
            } else {
                fromOfCall = self.from;
            }
            
            self.stringeeCall = [[StringeeCall alloc] initWithStringeeClient:[StringeeImplement instance].stringeeClient from:fromOfCall to:self.to];
            
            NSDictionary *customData = @{@"app-to-phone":@(!_isAppToApp)};
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:customData
                                                               options:NSJSONWritingPrettyPrinted
                                                                 error:nil];
            NSString *jsonString = [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@" " withString:@""];
            self.stringeeCall.customData = jsonString;
            self.stringeeCall.isVideoCall = self.isVideoCall;
            
            self.stringeeCall.delegate = self;
            [self.stringeeCall makeCallWithCompletionHandler:^(BOOL status, int code, NSString *message, NSString *data) {
                NSLog(@"makeCallWithCompletionHandler %@", message);
                if (!status) {
                    // Nếu make call không thành công thì kết thúc cuộc gọi
                    [self endCallAndDismissWithTitle:@"Cuộc gọi không thành công"];
                    [self showCustomAlertViewTimeout];
                }
            }];
            // truoc khi start outgoing thi phai close systemcall truoc do
//            if ([[SPManager instance] isSystemCall]) {
//                [[CallManager sharedInstance] endCall];
//            }
            [[CallManager sharedInstance] startCallWithPhoneNumber:self.to calleeName:self.username isVideoCall:self.isVideoCall engagementID:self.engagementID];
        }
        
    }
    [self addPulsing];
}


-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

//MARK: - Action

- (IBAction)endCallTapped:(UIButton *)sender {
    [self hangup];
}

- (IBAction)muteTapped:(UIButton *)sender {
    [self mute];
}

- (IBAction)speakerTapped:(UIButton *)sender {
    
    if (isSpeaker) {
        [self.buttonSpeaker setBackgroundImage:[UIImage imageNamed:@"icon_speaker"] forState:UIControlStateNormal];
        [[StringeeAudioManager instance] setLoudspeaker:NO];
        isSpeaker = NO;
        
    } else {
        [self.buttonSpeaker setBackgroundImage:[UIImage imageNamed:@"icon_speaker_selected"] forState:UIControlStateNormal];
        [[StringeeAudioManager instance] setLoudspeaker:YES];
        isSpeaker = YES;
    }
//    [[EventTrackingManager shared] pushEventWithEventName:_isIncomingCall?@"customer_receive_call_tap_speaker":@"customer_call_tap_speaker" params:@{@"speaker_status": isSpeaker?@"on":@"off"} type:EventTrackerTypeGgAnalytics];

}


- (IBAction)acceptTapped:(UIButton *)sender {
    if (_screenMode == ScreenModeReplyRequest) {
        if ([self.stringeeCall enableLocalVideo:YES]) {
            [self.btCamera setBackgroundImage:[UIImage imageNamed:@"video_enable"] forState:UIControlStateNormal];
        }
        NSDictionary *acceptRequest = @{@"type" : @"answerCameraRequest",
                                         @"accept" : @(YES)
                                         };
        [self.stringeeCall sendCallInfo:acceptRequest completionHandler:^(BOOL status, int code, NSString *message) {

        }];
        [self updateScreenWithScreenMode:ScreenModeVideoCall];
        hasAcceptedVideo = YES;
    } else {
        [self answerCallWithAnimation:YES];
    }
}

- (IBAction)declineTapped:(UIButton *)sender {
    if (_screenMode == ScreenModeReplyRequest) {
        NSDictionary *declineRequest = @{@"type" : @"answerCameraRequest",
                                         @"accept" : @(NO)
                                         };
        [self.stringeeCall sendCallInfo:declineRequest completionHandler:^(BOOL status, int code, NSString *message) {
            self.buttonEndCall.hidden = NO;
            self.buttonAccept.hidden = YES;
            self.buttonDecline.hidden = YES;
        }];
        
        _screenMode = ScreenModeVoiceCall;
        [self updateScreenWithScreenMode:ScreenModeVoiceCall];

    } else {
        [self decline];
    }
}

- (IBAction)callpadTapped:(UIButton *)sender {
}

- (IBAction)switchVideoTapped:(UIButton *)sender {
    NSLog(@"switchVideoTapped");
    [self.stringeeCall switchCamera];
}

- (IBAction)cameraTapped:(UIButton *)sender {
    NSLog(@"cameraTapped");
    
    if (isEnableLocalVideo) {
        if ([self.stringeeCall enableLocalVideo:NO]) {
            isEnableLocalVideo = !isEnableLocalVideo;
            [self.btCamera setBackgroundImage:[UIImage imageNamed:@"video_disable"] forState:UIControlStateNormal];
            
            if (!hasAcceptedVideo && !_isVideoCall) {
                // Nếu chưa đồng ý video từ bên kia lần nào thì cứ gửi yêu cầu
                [self updateScreenWithScreenMode:-1];
                NSDictionary *requestInfo = @{@"type" : @"cameraRequest",
                                              @"request" : @(NO)
                                              };
                [self.stringeeCall sendCallInfo:requestInfo completionHandler:^(BOOL status, int code, NSString *message) {
                    NSLog(@"%@", message);
                }];
            }
        }
    } else {
        if ([self.stringeeCall enableLocalVideo:YES]) {
            
            isEnableLocalVideo = !isEnableLocalVideo;
            [self.btCamera setBackgroundImage:[UIImage imageNamed:@"video_enable"] forState:UIControlStateNormal];
            
            if (!hasAcceptedVideo && !_isVideoCall) {
                // Nếu chưa đồng ý video từ bên kia lần nào thì cứ gửi yêu cầu
                [self updateScreenWithScreenMode:ScreenModeRequestVideo];
                NSDictionary *requestInfo = @{@"type" : @"cameraRequest",
                                              @"request" : @(YES)
                                           };
                [self.stringeeCall sendCallInfo:requestInfo completionHandler:^(BOOL status, int code, NSString *message) {
                    NSLog(@"%@", message);
                }];
            }
        }
    }
}

//MARK: - Private method

- (void)checkCallTimeOut {
    NSLog(@"checkCallTimeOut");
    
    interval += 10;
    if (interval >= [SPManager instance].calTimeOut /*&& !timer*/) {
        // Quá thời gian quy định mà chưa có kết nối thoại thì sẽ kiểm tra để ngắt máy
        [[StringeeImplement instance] stopRingingWithMessage:@"Không có phản hồi"];
        [[CallManager sharedInstance] endCall];
        
        if (_isIncomingCall) {
            [self decline];
        } else {
            [self hangup];
        }
        
        [self endCallAndDismissWithTitle:@""];
        [self showCustomAlertViewTimeout];
    }
}

- (void)answerCallWithAnimation:(BOOL)isAnimation {
    [self stopSound];
    hasAnsweredCall = YES;
    if (isAnimation) {
        self.buttonDecline.hidden = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.4 animations:^{
                self.buttonAccept.center = self.buttonEndCall.center;
                [self.buttonAccept setTransform:CGAffineTransformRotate(self.buttonAccept.transform, M_PI *3/4)];
                
            } completion:^(BOOL finished) {
                
                [self.stringeeCall answerCallWithCompletionHandler:^(BOOL status, int code, NSString *message) {
                    NSLog(@"%@", message);
                    if (!status) {
                        [self endCallAndDismissWithTitle:@"Kết thúc cuộc gọi"];
                        [self showCustomAlertViewTimeout];
                    }
                }];
                
                [self updateScreenWithScreenMode:-1];
            }];
        });
    } else {
        [self updateScreenWithScreenMode:-1];

        [self.stringeeCall answerCallWithCompletionHandler:^(BOOL status, int code, NSString *message) {
            NSLog(@"%@", message);
            if (!status) {
                [self endCallAndDismissWithTitle:@"Kết thúc cuộc gọi"];
                [self showCustomAlertViewTimeout];
            }
        }];
    }

}

- (void)hangup {
    [self.stringeeCall hangupWithCompletionHandler:^(BOOL status, int code, NSString *message) {
        NSLog(@"%@", message);
        if (!status) {
            [self endCallAndDismissWithTitle:@"Kết thúc cuộc gọi"];
        }
    }];
}

- (void)decline {
    isDecline = YES;
    [self stopSound];
    [self.stringeeCall rejectWithCompletionHandler:^(BOOL status, int code, NSString *message) {
        NSLog(@"%@", message);
        if (!status) {
            [self endCallAndDismissWithTitle:@"Kết thúc cuộc gọi"];
        }
    }];
}

- (void)mute {
    if (isMute) {
        [self.stringeeCall mute:NO];
        isMute = NO;
        [self.buttonMute setBackgroundImage:[UIImage imageNamed:@"icon_mute"] forState:UIControlStateNormal];
    } else {
        [self.stringeeCall mute:YES];
        isMute = YES;
        [self.buttonMute setBackgroundImage:[UIImage imageNamed:@"icon_mute_selected"] forState:UIControlStateNormal];
    }
//    [[EventTrackingManager shared] pushEventWithEventName:_isIncomingCall?@"customer_receive_call_tap_mute":@"customer_call_tap_mute" params:@{@"mute_status": isMute?@"on":@"off"} type:EventTrackerTypeGgAnalytics];
}

// Show thông báo và kết thúc cuộc gọi
- (void)endCallAndDismissWithTitle:(NSString *)title {
    
    [self removePulsing];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];

    self.labelConnecting.text = title;
    self.lbConnectingVC.text = title;
    self.view.userInteractionEnabled = NO;
    
    self.blurView.alpha = 0.4;
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
    [self endStatsReports];
    
    CFRunLoopStop(CFRunLoopGetCurrent());
    [timeoutTimer invalidate];
    timeoutTimer = nil;
    
    int call_diration = timeMin*60 + timeSec;
//    [[EventTrackingManager shared] pushEventWithEventName:_isIncomingCall?@"customer_receive_call_tap_end":@"customer_call_tap_end" params:@{@"call_duration": [NSNumber numberWithInt:call_diration]} type:EventTrackerTypeGgAnalytics];
    
    [Utils delayCallback:^{
        UIViewController *vc = self.presentingViewController;
        while (vc.presentingViewController) {
            vc = vc.presentingViewController;
        }
        [vc dismissViewControllerAnimated:YES completion:^{
            [SPManager instance].isClickOutGoing = SyncStateCallingNone;
            [SPManager instance].callingViewController = nil;
            [[CallManager sharedInstance] endCall];
        }];
        
    } forTotalSeconds:0.7];
}

// Thực hiện khối lệnh sau 1 khoảng thời gian


// Bắt đầu đếm thời gian cuộc gọi
- (void)startTimer {
    if (!timer) {
        self.isCalling = YES;
        timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        [timer fire];
        
        CFRunLoopStop(CFRunLoopGetCurrent());
        [timeoutTimer invalidate];
        timeoutTimer = nil;
        [self removePulsing];
    }

}

// Hàm nhảy dây
- (void)timerTick:(NSTimer *)timer
{
    timeSec++;
    if (timeSec == 60)
    {
        timeSec = 0;
        timeMin++;
    }
    NSString* timeNow = [NSString stringWithFormat:@"%02d:%02d", timeMin, timeSec];
    if (self.labelConnecting.hidden) {
        self.labelConnecting.hidden = NO;
    }
    self.labelConnecting.text= timeNow;
    
    if (self.lbConnectingVC.hidden) {
        self.lbConnectingVC.hidden = NO;
    }
    self.lbConnectingVC.text= timeNow;
}

// Kết thúc đếm thời gian cuộc gọi
- (void)stopTimer {
    CFRunLoopStop(CFRunLoopGetCurrent());
    [timer invalidate];
    timer = nil;
    NSString* timeNow = [NSString stringWithFormat:@"%02d:%02d", timeMin, timeSec];
    self.labelConnecting.text= timeNow;
    self.lbConnectingVC.text= timeNow;
}

- (void)switchRouteTo:(AVAudioSessionPortOverride)port {
    
    NSError *error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategorySoloAmbient error:&error];
    [session setActive: YES error:&error];
    
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:port
                                                       error:&error];
    if(error)
    {
        NSLog(@"Error: AudioSession cannot use speakers");
    }
}

- (void)beginStatsReports {
    arrAudioBw = [NSMutableArray new];
    reportTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(statsReport) userInfo:nil repeats:YES];
}

- (void)endStatsReports {
    [reportTimer invalidate];
    reportTimer = nil;
    if (arrAudioBw.count > 0)
    {
        long long svgAudio = [self caculatorAvgQuality];
        [self trackingQualityWith:svgAudio];
        NSLog(@"svgAudio -- %lld",svgAudio);
    }
    arrAudioBw = nil;
}

- (void)statsReport {
        [self.stringeeCall statsWithCompletionHandler:^(NSDictionary<NSString *,NSString *> *values) {
            [self checkAudioQualityWithStats:values];
        }];
}

// Đánh giá chất lượng mạng dựa trên các thông số
- (void)checkAudioQualityWithStats:(NSDictionary *)stats {
    
    NSTimeInterval audioTimeStamp = [[NSDate date] timeIntervalSince1970];
    
    NSNumber *byteReceived = [stats objectForKey:@"bytesReceived"];
    
    if (byteReceived.longLongValue != 0) {
        if (prevAudioTimeStamp == 0) {
            prevAudioTimeStamp = audioTimeStamp;
            
            prevAudioBytes = byteReceived.longLongValue;
        }
        
        if (audioTimeStamp - prevAudioTimeStamp > TIME_WINDOW) {
            
            // Tính tỉ lệ mất gói
            NSNumber *packetLost = stats[@"packetsLost"];
            NSNumber *packetsReceived = stats[@"packetsReceived"];
            
            if (prevAudioPacketReceived != 0) {
                long long pl = packetLost.longLongValue - prevAudioPacketLost;
                long long pr = packetsReceived.longLongValue - prevAudioPacketReceived;
                
                long long pt = pl + pr;
                
                if (pt > 0) {
                    audioPLRatio = (double)pl / (double)pt;
                }
            }
            
            prevAudioPacketLost = packetLost.longLongValue;
            prevAudioPacketReceived = packetsReceived.longLongValue;
            
            // Tính băng thông video
            audioBw = (long long) ((8 * (byteReceived.longLongValue - prevAudioBytes)) / (audioTimeStamp - prevAudioTimeStamp));
            prevAudioTimeStamp = audioTimeStamp;
            prevAudioBytes = byteReceived.longLongValue;
            
            [arrAudioBw addObject:@(audioBw)];
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if ([StringeeImplement instance].stringeeClient.hasConnected) {
                    
                    if (audioBw >= 35000) {
                        [self.imageInternetQualityVC setImage:[UIImage imageNamed:@"exellent"]];
                        [self.imageInternetQuality setImage:[UIImage imageNamed:@"exellent"]];
                    } else if (audioBw >= 25000 && audioBw < 35000) {
                        [self.imageInternetQualityVC setImage:[UIImage imageNamed:@"good"]];
                        [self.imageInternetQuality setImage:[UIImage imageNamed:@"good"]];
                    } else if (audioBw > 15000 && audioBw < 25000) {
                        [self.imageInternetQualityVC setImage:[UIImage imageNamed:@"average"]];
                        [self.imageInternetQuality setImage:[UIImage imageNamed:@"average"]];
                    } else {
                        [self.imageInternetQualityVC setImage:[UIImage imageNamed:@"poor"]];
                        [self.imageInternetQuality setImage:[UIImage imageNamed:@"poor"]];
                    }
                } else {
                    [self.imageInternetQualityVC setImage:[UIImage imageNamed:@"no_connect"]];
                    [self.imageInternetQuality setImage:[UIImage imageNamed:@"no_connect"]];
                }
                
            });
            
        }
    }
}
-(long long) caculatorAvgQuality
{
    long long sumAudio = 0;
    NSInteger countAudio = arrAudioBw.count;
    for (id obj in arrAudioBw) {
        long long item = [obj longLongValue];
        sumAudio += item;
    }
    long long svgAudio = countAudio > 0?sumAudio/countAudio: 0;
    return svgAudio;
}
-(void)trackingQualityWith:(long long)svgAudio
{
    if (_stringeeCall.callId) {
//        NSString *strAccessToken = [[BeCommon shareCommonMethods] passValidString:[SPManager instance].customerInfo.publicAccessTokenString];
//        NSDictionary *params = @{@"quality": [NSNumber numberWithLongLong:svgAudio],
//                                 @"call_id": _stringeeCall.callId,
//                                 @"access_token": strAccessToken,
//                                 };
//        [GlobalService putTrackingSignalWithParameters:params completionHandler:^(id responseObject) {
//            NSLog(@"putTrackingSignalWithParameters");
//        }];
    }
}
- (void)didSessionRouteChange:(NSNotification *)notification {
    NSLog(@"didSessionRouteChange");
    dispatch_async(dispatch_get_main_queue(), ^{
        AVAudioSessionRouteDescription *route = [[AVAudioSession sharedInstance] currentRoute];
        
        for( AVAudioSessionPortDescription *portDescription in route.outputs ) {
            if ([portDescription.portType isEqualToString:AVAudioSessionPortBuiltInSpeaker]) {
                [self.buttonSpeaker setBackgroundImage:[UIImage imageNamed:@"icon_speaker_selected"] forState:UIControlStateNormal];
                self->isSpeaker = YES;
//                [[EventTrackingManager shared] pushEventWithEventName:_isIncomingCall?@"customer_receive_call_tap_speaker":@"customer_call_tap_speaker" params:@{@"speaker_status": isSpeaker?@"on":@"off"} type:EventTrackerTypeGgAnalytics];
                return;
            } else {
                [self.buttonSpeaker setBackgroundImage:[UIImage imageNamed:@"icon_speaker"] forState:UIControlStateNormal];
                self->isSpeaker = NO;
//                [[EventTrackingManager shared] pushEventWithEventName:_isIncomingCall?@"customer_receive_call_tap_speaker":@"customer_call_tap_speaker" params:@{@"speaker_status": isSpeaker?@"on":@"off"} type:EventTrackerTypeGgAnalytics];
                return;
            }
        }
    });
    

    
}

- (BOOL)isHeadsetPluggedIn {
    AVAudioSessionRouteDescription *route = [[AVAudioSession sharedInstance] currentRoute];
    
    for( AVAudioSessionPortDescription *portDescription in route.outputs ) {
        if ([portDescription.portType isEqualToString:AVAudioSessionPortHeadphones]) {
            return YES;
        }
    }
    return NO;
}

- (void)updateScreenWithScreenMode:(ScreenMode)screenMode {
    
    if (screenMode >= 0) {
        _screenMode = screenMode;
    } else {
        [self checkScreenMode];
    }
    
    switch (_screenMode) {
            
        case ScreenModeOutgoingVoiceCall:
            self.voiceCallInfoView.hidden = NO;
            self.optionView.hidden = NO;
            self.videoCallInfoView.hidden = YES;
            self.buttonEndCall.hidden = NO;
            self.buttonAccept.hidden = YES;
            self.buttonDecline.hidden = YES;
            self.localView.hidden = YES;
            self.remoteView.hidden = YES;
            self.videoBlurView.hidden = YES;
            break;
            
        case ScreenModeOutgoingVideoCall:
            self.voiceCallInfoView.hidden = YES;
            self.optionView.hidden = NO;
            self.videoCallInfoView.hidden = NO;
            self.buttonEndCall.hidden = NO;
            self.buttonAccept.hidden = YES;
            self.buttonDecline.hidden = YES;
            self.localView.hidden = NO;
            self.remoteView.hidden = YES;
            self.videoBlurView.hidden = YES;
            break;
            
        case ScreenModeIncomingVoiceCall:
            self.voiceCallInfoView.hidden = NO;
            self.optionView.hidden = YES;
            self.videoCallInfoView.hidden = YES;
            self.buttonEndCall.hidden = YES;
            self.buttonAccept.hidden = NO;
            self.buttonDecline.hidden = NO;
            self.localView.hidden = YES;
            self.remoteView.hidden = YES;
            self.videoBlurView.hidden = YES;
            break;
            
        case ScreenModeIncomingVideoCall:
            self.voiceCallInfoView.hidden = NO;
            self.optionView.hidden = YES;
            self.videoCallInfoView.hidden = YES;
            self.buttonEndCall.hidden = YES;
            self.buttonAccept.hidden = NO;
            self.buttonDecline.hidden = NO;
            self.localView.hidden = YES;
            self.remoteView.hidden = YES;
            self.videoBlurView.hidden = YES;
            break;
            
        case ScreenModeVoiceCall:
            self.voiceCallInfoView.hidden = NO;
            self.optionView.hidden = NO;
            self.videoCallInfoView.hidden = YES;
            self.buttonEndCall.hidden = NO;
            self.buttonAccept.hidden = YES;
            self.buttonDecline.hidden = YES;
            self.localView.hidden = YES;
            self.remoteView.hidden = YES;
            self.videoBlurView.hidden = YES;
            break;
            
        case ScreenModeVideoCall:{
            self.voiceCallInfoView.hidden = YES;
            self.optionView.hidden = NO;
            self.videoCallInfoView.hidden = NO;
            self.buttonEndCall.hidden = NO;
            self.buttonAccept.hidden = YES;
            self.buttonDecline.hidden = YES;
            self.localView.hidden = NO;
            self.remoteView.hidden = NO;
            self.view.userInteractionEnabled = YES;
            self.videoBlurView.hidden = YES;
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
            
            // Chuyển local view thành hình nhỏ
            [UIView animateWithDuration:0.2 animations:^{
                self.localView.frame = CGRectMake(SCR_WIDTH - 10 - 100, self.videoCallInfoView.frame.size.height + 10, 100, 120);
                self.stringeeCall.localVideoView.frame = CGRectMake(0, 0, 100, 120);
            }];
        } break;
            
        case ScreenModeRequestVideo:
            self.voiceCallInfoView.hidden = NO;
            self.optionView.hidden = NO;
            self.videoCallInfoView.hidden = YES;
            self.buttonEndCall.hidden = NO;
            self.buttonAccept.hidden = YES;
            self.buttonDecline.hidden = YES;
            self.localView.hidden = NO;
            self.remoteView.hidden = YES;
            self.videoBlurView.hidden = YES;
            self.localView.frame = CGRectMake(0, 0, SCR_WIDTH, SCR_HEIGHT);
            self.stringeeCall.localVideoView.frame = CGRectMake(0, 0, SCR_WIDTH, SCR_HEIGHT);
            break;
            
        case ScreenModeReplyRequest:
            self.voiceCallInfoView.hidden = YES;
            self.optionView.hidden = YES;
            self.videoCallInfoView.hidden = YES;
            self.buttonEndCall.hidden = YES;
            self.buttonAccept.hidden = NO;
            self.buttonDecline.hidden = NO;
            self.localView.hidden = YES;
            self.remoteView.hidden = NO;
            self.videoBlurView.hidden = NO;
            self.lbRequestVideo.text = [NSString stringWithFormat:@"%@ đang chia sẻ video...", self.username];
            [self.buttonAccept setTransform:CGAffineTransformIdentity];
            [self.buttonAccept setBackgroundImage:[UIImage imageNamed:@"icon_accept_video_call"] forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
}

- (void)checkScreenMode {
    if (_screenMode != ScreenModeRequestVideo && _screenMode != ScreenModeReplyRequest) {
        if (_isIncomingCall) {
            // Gọi đến
            if (_isVideoCall) {
                if (hasAnsweredCall) {
                    // Đã trả lời
                    _screenMode = ScreenModeVideoCall;
                } else {
                    _screenMode = ScreenModeIncomingVideoCall;
                }
            } else {
                if (hasAnsweredCall) {
                    // Đã trả lời
                    _screenMode = ScreenModeVoiceCall;
                } else {
                    _screenMode = ScreenModeIncomingVoiceCall;
                }
            }
        } else {
            // Gọi đi
            if (_isVideoCall) {
                // Gọi video
                if (hasAnsweredCall) {
                    // Đã trả lời
                    _screenMode = ScreenModeVideoCall;
                } else {
                    _screenMode = ScreenModeOutgoingVideoCall;
                }
            } else {
                // Gọi voice
                if (hasAnsweredCall) {
                    // Đã trả lời
                    _screenMode = ScreenModeVoiceCall;
                } else {
                    _screenMode = ScreenModeOutgoingVoiceCall;
                }
            }
        }
    }
}

- (void)viewTapped {
    NSLog(@"viewTapped");
    if (hasAnsweredCall && _screenMode == ScreenModeVideoCall) {
        if (isShowOption) {
            isShowOption = !isShowOption;
            [UIView animateWithDuration:0.3 animations:^{
                self.videoCallInfoView.transform = CGAffineTransformMakeTranslation(0, -self.videoCallInfoView.frame.size.height);
                self.localView.transform = CGAffineTransformMakeTranslation(0, -self.videoCallInfoView.frame.size.height);
                self.optionView.transform = CGAffineTransformMakeTranslation(0, SCR_HEIGHT - self.optionView.frame.origin.y + 10);
                self.buttonEndCall.transform = CGAffineTransformMakeTranslation(0, SCR_HEIGHT - self.buttonEndCall.frame.origin.y + 10);
            }];
        } else {
            isShowOption = !isShowOption;
            [UIView animateWithDuration:0.3 animations:^{
                self.videoCallInfoView.transform = CGAffineTransformMakeTranslation(0, 0);
                self.localView.transform = CGAffineTransformMakeTranslation(0, 0);
                self.optionView.transform = CGAffineTransformMakeTranslation(0, 0);
                self.buttonEndCall.transform = CGAffineTransformMakeTranslation(0, 0);
            }];
        }
    }
}

// MARK: - Play Ringing Sound

- (void)startSound {

    if (@available(iOS 10, *)) {

    } else {
        NSString *soundFilePath;
        NSURL *soundFileURL;
        int loopIndex = 10;
        
        if (self.isIncomingCall) {
            soundFilePath = [[NSBundle mainBundle] pathForResource:@"incoming_call"  ofType:@"aif"];
            soundFileURL = [NSURL fileURLWithPath:soundFilePath];
            
            [self switchRouteTo:AVAudioSessionPortOverrideSpeaker];
            
            ringAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:nil];
            ringAudioPlayer.numberOfLoops = loopIndex;
            [ringAudioPlayer prepareToPlay];
            [ringAudioPlayer play];
        }
    }
}

- (void)stopSound {
    [ringAudioPlayer stop];
    ringAudioPlayer = nil;
    
}
//MARK: - Play ring outgoing
-(void) startRingOutgoing:(SignalingState)signalingState
{
    NSString *strNameAudio = @"";
    NSString *strType = @"";
    switch (signalingState) {
        case SignalingStateRinging:
        {
            strNameAudio = @"outgoing_tone";
            strType = @"mp3";
            
        }
            break;
        case SignalingStateBusy:
        {
            strNameAudio = @"busy_signal";
            strType = @"mp3";
        }
            break;
        case SignalingStateEnded:
        {
            strNameAudio = @"end_call_tututu";
            strType = @"caf";
        }
            break;
            
        default:
            break;
    }
    if (!self.isIncomingCall && strNameAudio.length > 0) {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            //enable audio session
            NSError *error = nil;
            AVAudioSession *session = [AVAudioSession sharedInstance];
            [session setActive: YES error:&error];
            if(error)
            {
                NSLog(@"Error: AudioSession cannot use speakers");
            }
            //read audio from
            NSString *soundFilePath;
            NSURL *soundFileURL;
            int loopIndex = 10;
            soundFilePath = [[NSBundle mainBundle] pathForResource:strNameAudio  ofType:strType];
            soundFileURL = [NSURL fileURLWithPath:soundFilePath];
            ringAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:nil];
            ringAudioPlayer.numberOfLoops = loopIndex;
            
            [ringAudioPlayer prepareToPlay];
            [ringAudioPlayer play];

        });
        
    }
    
}
-(void) stopRingOutgoing
{
    [ringAudioPlayer stop];
    ringAudioPlayer = nil;
}

// MARK: - StringeeCallDelegate

- (void)didChangeSignalingState:(StringeeCall *)stringeeCall signalingState:(SignalingState)signalingState reason:(NSString *)reason sipCode:(int)sipCode sipReason:(NSString *)sipReason {
    NSLog(@"*********Callstate: %ld", (long)signalingState);
    [StringeeImplement instance].signalingState = signalingState;
    [self stopRingOutgoing];
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (signalingState) {
                
            case SignalingStateCalling:
                self.labelConnecting.hidden = NO;
                self.labelConnecting.text = @"Đang liên hệ...";
                
                self.lbConnectingVC.text = @"Đang liên hệ...";
                break;
                
            case SignalingStateRinging:
                self.labelConnecting.text = @"Đang đổ chuông...";
                self.lbConnectingVC.text = @"Đang đổ chuông...";
                [self startRingOutgoing: SignalingStateRinging];
                break;
                
            case SignalingStateAnswered: {
                hasAnsweredCall = YES;
                if (hasConnectedMedia) {
                    [self startTimer];
                } else {
                    self.labelConnecting.text = @"Đang kết nối...";
                    self.lbConnectingVC.text = @"Đang kết nối...";
                }
            } break;
                
            case SignalingStateBusy: {
                [self stopTimer];
                [self endCallAndDismissWithTitle:@"Số máy bận"];
                [self startRingOutgoing: SignalingStateBusy];
                if (@available(iOS 10, *)) {
                    [[CallManager sharedInstance] endCall];
                }
            } break;
                
            case SignalingStateEnded: {
                [self stopTimer];
                [self endCallAndDismissWithTitle:@"Kết thúc cuộc gọi"];
                [self startRingOutgoing: SignalingStateEnded];
                [[StringeeImplement instance] stopRingingWithMessage:[NSString stringWithFormat:@"Bạn đã bỏ lỡ cuộc gọi từ %@", self.stringeeCall.from]];
                if (@available(iOS 10, *)) {
                    [[CallManager sharedInstance] endCall];
                }
            } break;
        }
    });
}

- (void)didChangeMediaState:(StringeeCall *)stringeeCall mediaState:(MediaState)mediaState {
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (mediaState) {
            case MediaStateConnected:
                hasConnectedMedia = YES;
                if (hasAnsweredCall) {
                    [self startTimer];
                }
                [self beginStatsReports];
                if (self.stringeeCall.callType == CallTypeInternalCallAway || self.stringeeCall.callType == CallTypeInternalIncomingCall) {
                    self.btCamera.enabled = YES;
                }
                [self updateScreenWithScreenMode:-1];
                break;
            case MediaStateDisconnected:
                break;
            default:
                break;
        }
    });
}

- (void)didHandleOnAnotherDevice:(StringeeCall *)stringeeCall signalingState:(SignalingState)signalingState reason:(NSString *)reason sipCode:(int)sipCode sipReason:(NSString *)sipReason {
    NSLog(@"didHandleOnAnotherDevice %ld", (long)signalingState);
    if (signalingState == SignalingStateAnswered) {
        [[StringeeImplement instance] stopRingingWithMessage:@"Cuộc gọi đã được điều khiển ở thiết bị khác"];
        [[CallManager sharedInstance] endCall];
        [self endCallAndDismissWithTitle:@"Cuộc gọi đã được điều khiển ở thiết bị khác"];
    }
}

- (void)didReceiveLocalStream:(StringeeCall *)stringeeCall {
    NSLog(@"didReceiveLocalStream");
    [self updateScreenWithScreenMode:-1];
    
    stringeeCall.localVideoView.frame = CGRectMake(0, 0, self.localView.frame.size.width, self.localView.frame.size.height);
    [self.localView addSubview:stringeeCall.localVideoView];
}

- (void)didReceiveRemoteStream:(StringeeCall *)stringeeCall {
    NSLog(@"didReceiveRemoteStream");
    
    // Hiện thị remote stream
    stringeeCall.remoteVideoView.frame = CGRectMake(0, 0, SCR_WIDTH, SCR_HEIGHT);
    stringeeCall.remoteVideoView.delegate = self;
    [self.remoteView insertSubview:stringeeCall.remoteVideoView atIndex:0];


}

- (void)didReceiveCallInfo:(StringeeCall *)stringeeCall info:(NSDictionary *)info {
    
    NSLog(@"didReceiveCallInfo %@", info);
    
    NSString *type = [info objectForKey:@"type"];
    if ([type isEqualToString:@"cameraRequest"]) {
        // Nhận yêu cầu từ bên kia
        BOOL request = [[info objectForKey:@"request"] boolValue];
        if (request) {
            // Yêu cầu bật video
            [self updateScreenWithScreenMode:ScreenModeReplyRequest];
        } else {
            // Hủy yêu cầu
            [self updateScreenWithScreenMode:ScreenModeVoiceCall];
        }
    } else if ([type isEqualToString:@"answerCameraRequest"]) {
        // Nhận được phản hồi từ bên kia
        hasAcceptedVideo = [[info objectForKey:@"accept"] boolValue];
        if (hasAcceptedVideo) {
            // Đồng ý bật video
            [self updateScreenWithScreenMode:ScreenModeVideoCall];

        } else {
            // Yêu cầu bị tự chối
            if ([self.stringeeCall enableLocalVideo:NO]) {
                isEnableLocalVideo = NO;
                [self.btCamera setBackgroundImage:[UIImage imageNamed:@"video_disable"] forState:UIControlStateNormal];
                [self updateScreenWithScreenMode:ScreenModeVoiceCall];
            }
        }
        
    }
}

// MARK: - StringeeRemoteViewDelegate

- (void)videoView:(StringeeRemoteVideoView *)videoView didChangeVideoSize:(CGSize)size {
    NSLog(@"didChangeVideoSize (%f : %f)", size.width, size.height);
    
    // Thay đổi frame của StringeeRemoteVideoView khi kích thước video thay đổi
    
    CGFloat superWidth = self.remoteView.frame.size.width;
    CGFloat superHeight = self.remoteView.frame.size.height;
    
    CGFloat newWidth;
    CGFloat newHeight;
    
    if (size.width > size.height) {
        newWidth = superWidth;
        newHeight = newWidth * size.height / size.width;
        
        [videoView setFrame:CGRectMake(0, (superHeight - newHeight) / 2, newWidth, newHeight)];
        
    } else {
        newHeight = superHeight;
        newWidth = newHeight * size.width / size.height;
        
        [videoView setFrame:CGRectMake((superWidth - newWidth) / 2, 0, newWidth, newHeight)];
    }
}
//MARK: - show alert when timeout
- (void)showCustomAlertViewTimeout {
//    if(!self.isIncomingCall)
//    {
//    SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"" andMessage:@"Cuộc gọi miễn phí không thể thực hiện do vấn đề kết nối mạng từ người nhận. Chuyển sang cuộc gọi thông thường"];
//    [alertView setMessageColor:[AppColors themeBlackColor]];
//    [alertView addButtonWithTitle:@"Huỷ bỏ"
//                             type:SIAlertViewButtonTypeCancel
//                          handler:^(SIAlertView *alertView) {
//                              NSLog(@"Cancel Clicked");
//                          }];
//    [alertView addButtonWithTitle:@"Đồng ý"
//                             type:SIAlertViewButtonTypeCancel
//                          handler:^(SIAlertView *alertView) {
//                              NSLog(@"Ok Clicked");
//                              [Utils delayCallback:^{
//                                  [self callDriverPhoneNumber];
//                              } forTotalSeconds:0.5];
//                          }];
//
//    alertView.transitionStyle = SIAlertViewTransitionStyleFade;
//    [alertView show];
//    }
}
-(void)callDriverPhoneNumber
{
//    if ([self.engagementID isEqualToString:[[CommonFunctions shareCommonMethods] passValidString:[FindDriverManager handleDriverManager].rideInfoDictionary.engagementID]]) {
//        if ([NSString stringWithFormat:@"%@",[FindDriverManager handleDriverManager].rideInfoDictionary.rideInProgress].length != 0) {
//            //1. In case masking feature is ON: The app calls OS default dialer and auto fill masking phone number. => after that users can make a phone to phone call
//            //2. In case masking feature is OFF/Unknown: The app calls OS default dialer and auto fill driver phone number. => after that users can make a phone to phone call
//            NSString *strDriverPhoneNumber = [[SPManager instance] getNumberMaskWithTrip:[FindDriverManager handleDriverManager].rideInfoDictionary.engagementID withDriverPhoneNumber:[FindDriverManager handleDriverManager].rideInfoDictionary.driverPhoneNumber];
//            NSURL *phoneUrl = [NSURL URLWithString:[NSString  stringWithFormat:@"telprompt:%@",strDriverPhoneNumber]];
//            if ([[UIApplication sharedApplication] canOpenURL:phoneUrl]) {
//                //            NSString *logEventString = @"Call to driver made when not arrived";
//                //[[CommonFunctions shareCommonMethods] googleAnalyticsWithEventName:logEventString];
//                [[UIApplication sharedApplication] openURL:phoneUrl];
//                [[EventTrackingManager shared] pushEventWithEventName:@"ride_details_tap_on_call" params:@{
//                                                                                                           @"ETA": [[NSUserDefaults standardUserDefaults] integerForKey:USER_RIDE_STATUS] == userRideStateDriverAcceptedRequest ? [FindDriverManager handleDriverManager].rideInfoDictionary.driverUpcomingTime : [FindDriverManager handleDriverManager].rideInfoDictionary.rideTime,
//                                                                                                           @"vehicle_type": ([FindDriverManager handleDriverManager].selectedVehicleType == VEEP_VEHICAL_TYPE_TWO_WHEEL_CARRY_PEOPLE ? @"bike": ([FindDriverManager handleDriverManager].selectedVehicleType == VEEP_VEHICAL_TYPE_FOUR_SEATS ? @"4seat_car" : @"7seat_car"))
//                                                                                                           } type:EventTrackerTypeGgAnalytics];
//            } else {
//                [[CommonFunctions shareCommonMethods] showCustomAlertViewFromCommonWithTitle:nil message:[ApplicationStrings Call_Facility_Unavailable] withButtonTitle:[ApplicationStrings ok]];
//            }
//        }
//    }
//    else
//    {
//        NSURL *phoneUrl = [NSURL URLWithString:[NSString  stringWithFormat:@"telprompt:%@",@"1900232345"]];
//        if ([[UIApplication sharedApplication] canOpenURL:phoneUrl]) {
//            //            NSString *logEventString = @"Call to driver made when not arrived";
//            //[[CommonFunctions shareCommonMethods] googleAnalyticsWithEventName:logEventString];
//            [[UIApplication sharedApplication] openURL:phoneUrl];
//        }
//        else {
//            [[CommonFunctions shareCommonMethods] showCustomAlertViewFromCommonWithTitle:nil message:[ApplicationStrings Call_Facility_Unavailable] withButtonTitle:[ApplicationStrings ok]];
//        }
//    }
}

//MARK: - pulsing call
-(void) setuPulsing
{
    isAnablePulsing = YES;
    self.view.backgroundColor = [Utils colorWithHexString:@"FFBB00"];
    if (/*!self.isIncomingCall && */isAnablePulsing == YES) {
        self.imgBackground.alpha = 0;
    }
    else
    {
        self.imgBackground.alpha = 1;
    }
}
-(void) addPulsing
{
    if (/*!self.isIncomingCall && */self.isCalling == NO && isAnablePulsing == YES) {
        self.imgBackground.alpha = 0;
//        pulsingCall = [[PulsingAnimationCall alloc] init];
//        [self.imgBackground.superview.layer insertSublayer:pulsingCall below:self.optionView.layer];
//        CGPoint position = CGPointMake([UIScreen mainScreen].bounds.size.width/2, [UIScreen mainScreen].bounds.size.height/2); //self.imgBackground.center;
//        position.y = position.y - 20;
//        pulsingCall.position = position;
//        [pulsingCall start];
    }
}
-(void) removePulsing
{
//    if (pulsingCall && isAnablePulsing == YES) {
//        [pulsingCall removeFromSuperlayer];
//        pulsingCall = nil;
        [UIView animateWithDuration:1.0 animations:^{
            self.imgBackground.alpha = 1;
        } completion:^(BOOL finished) {
        }];
//    }
}
@end
