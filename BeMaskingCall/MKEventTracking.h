//
//  MKEventTracking.h
//  MaskingCall
//
//  Created by manh.le on 5/24/19.
//  Copyright © 2019 manh.le. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@protocol MKEventTrackingDelegate <NSObject>
- (void) pushEventWithEventName:(NSString*)name params:(NSDictionary*)params;
@end

@interface MKEventTracking : NSObject
+ (MKEventTracking *)instance;
@property (nonatomic, weak) id<MKEventTrackingDelegate> delegate;
- (void) pushEventWithEventName:(NSString*)name params:(NSDictionary*)params;
@end

NS_ASSUME_NONNULL_END
