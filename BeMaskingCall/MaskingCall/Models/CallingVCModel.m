//
//  CallingVCModel.m
//  MaskingCall
//
//  Created by manh.le on 5/24/19.
//  Copyright © 2019 manh.le. All rights reserved.
//

#import "CallingVCModel.h"

@implementation CallingVCModel
- (instancetype)init {
    self = [super init];
    if (self) {
        _strImgBackground = @"bg_ellipse";
        _strImgSpeakerOff = @"call_speakeroff";
        _strImgSpeakerOn = @"call_speakeron";
        _strImgMuteOff = @"icon_mute";
        _strImgMuteOn = @"icon_mute_selected";
        _strImgAccept = @"icon_accept_call";
        _strImgDecline = @"call_end_call";
        _strColorBackground = @"FFBB00";
        _strColorText = @"203048";
        _strLabelTitle = @"Liên lạc tài xế qua be App";
        _strTracking_Receive_Call_Tap_Speaker = @"customer_receive_call_tap_speaker";
        _strTracking_Call_Tap_Speaker = @"customer_call_tap_speaker";
        _strTracking_Receive_Call_Tap_Mute = @"customer_receive_call_tap_mute";
        _strTracking_Call_Tap_Mute = @"customer_call_tap_mute";
        _strTracking_Receive_Call_Tap_End = @"customer_receive_call_tap_end";
        _strTracking_Call_Tap_End = @"customer_call_tap_end";
    }
    return self;
}
- (void) setupUIWithDriver:(BOOL) isDriver
{
    if (isDriver)
    {
        _strImgBackground = @"bg_ellipse";
        _strImgSpeakerOff = @"call_speakeroff";
        _strImgSpeakerOn = @"call_speakeron";
        _strImgMuteOff = @"icon_mute";
        _strImgMuteOn = @"icon_mute_selected";
        _strImgAccept = @"icon_accept_call";
        _strImgDecline = @"call_end_call";
        _strColorBackground = @"FFBB00";
        _strColorText = @"203048";
        _strLabelTitle = @"Liên lạc tài xế qua be App";
        _strTracking_Receive_Call_Tap_Speaker = @"driver_receive_call_tap_speaker";
        _strTracking_Call_Tap_Speaker = @"driver_call_tap_speaker";
        _strTracking_Receive_Call_Tap_Mute = @"driver_receive_call_tap_mute";
        _strTracking_Call_Tap_Mute = @"driver_call_tap_mute";
        _strTracking_Receive_Call_Tap_End = @"driver_receive_call_tap_end";
        _strTracking_Call_Tap_End = @"driver_call_tap_end";

    }
    else
    {
        _strImgBackground = @"bg_ellipse";
        _strImgSpeakerOff = @"ic_driver_speaker_off";
        _strImgSpeakerOn = @"ic_driver_speaker_on";
        _strImgMuteOff = @"ic_driver_mute_off";
        _strImgMuteOn = @"ic_driver_mute_on";
        _strImgAccept = @"ic_driver_accept_call";
        _strImgDecline = @"ic_driver_end_call";
        _strColorBackground = @"00003B";
        _strColorText = @"FFFFFF";
        _strLabelTitle = @"Liên lạc khách qua be App";
        _strTracking_Receive_Call_Tap_Speaker = @"customer_receive_call_tap_speaker";
        _strTracking_Call_Tap_Speaker = @"customer_call_tap_speaker";
        _strTracking_Receive_Call_Tap_Mute = @"customer_receive_call_tap_mute";
        _strTracking_Call_Tap_Mute = @"customer_call_tap_mute";
        _strTracking_Receive_Call_Tap_End = @"customer_receive_call_tap_end";
        _strTracking_Call_Tap_End = @"customer_call_tap_end";

    }
    
}
@end
