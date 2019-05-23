//
//  ConfigMaskingCallModel.m
//  Jugnoo
//
//  Created by manh.le on 4/23/19.
//  Copyright © 2019 Socomo Technologies. All rights reserved.
//

#import "ConfigMaskingCallModel.h"

@implementation ConfigMaskingCallModel
- (instancetype)initWithData:(NSDictionary *)data {
    self = [super init];
    if (self) {
        _isEnableCallInApp = (data[@"enable_call_in_app"] != nil && data[@"enable_call_in_app"] != [NSNull null]) ? [data[@"enable_call_in_app"] boolValue] : NO;
        _callTimeOut = (data[@"call_timeout"] != nil && data[@"call_timeout"] != [NSNull null]) ? [data[@"call_timeout"] intValue] : 15;
        NSArray *phones = (data[@"masking_numbers"] != nil && data[@"masking_numbers"] != [NSNull null]) ? data[@"masking_numbers"] : [[NSArray alloc] init];
        _calloutNumbers = phones;
        /*
         {
         "masking_numbers": [
         "842471008845",
         "842471008865",
         "842471008891"
         ],
         "enable_call_in_app": "1",
         "enable_masking_call": "1",
         "call_timeout": "15"
         }*/

    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder;
{
    [coder encodeObject:@(_isEnableCallInApp) forKey:@"isEnableCallInApp"];
    [coder encodeObject:@(_callTimeOut) forKey:@"callTimeOut"];
    [coder encodeObject:_calloutNumbers forKey:@"calloutNumbers"];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self != nil) {
        _isEnableCallInApp = (BOOL)[coder decodeObjectForKey:@"isEnableCallInApp"];
        _callTimeOut = (BOOL)[coder decodeObjectForKey:@"callTimeOut"];
        _calloutNumbers = (NSArray*)[coder decodeObjectForKey:@"calloutNumbers"];

    }
    return self;
}

@end
