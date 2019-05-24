//
//  MKEventTracking.m
//  MaskingCall
//
//  Created by manh.le on 5/24/19.
//  Copyright © 2019 manh.le. All rights reserved.
//

#import "MKEventTracking.h"

@implementation MKEventTracking
static MKEventTracking *traking = nil;

// MARK: - Init
+ (MKEventTracking *)instance {
    @synchronized(self) {
        if (traking == nil) {
            traking = [[self alloc] init];
        }
    }
    return traking;
}
- (void) pushEventWithEventName:(NSString*)name params:(NSDictionary*)params
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(pushEventWithEventName:params:)]) {
        [self.delegate pushEventWithEventName:name params:params];
    }
}
@end
