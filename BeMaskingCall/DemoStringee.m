//
//  DemoStringee.m
//  BeMaskingCall
//
//  Created by manh.le on 5/22/19.
//  Copyright © 2019 manh.le. All rights reserved.
//

#import "DemoStringee.h"
#import <Stringee/Stringee.h>
@implementation DemoStringee
static DemoStringee *spManager = nil;

// MARK: - Init
+ (DemoStringee *)instance {
    @synchronized(self) {
        if (spManager == nil) {
            spManager = [[self alloc] init];
        }
    }
    return spManager;
    
}
- (void)isHasConnect {
    NSLog(@"Le Dinh Manh");
}
@end
