//
//  ConfigMaskingCallModel.h
//  Jugnoo
//
//  Created by manh.le on 4/23/19.
//  Copyright © 2019 Socomo Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ConfigMaskingCallModel : NSObject
- (instancetype)initWithData:(NSDictionary *)data;
@property BOOL isEnableCallInApp;
@property int callTimeOut;
@property NSArray *calloutNumbers;
@end

NS_ASSUME_NONNULL_END
