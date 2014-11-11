//
//  Utility.m
//  iBeaconDemo
//
//  Created by MasashiMizuno on 2014/04/21.
//  Copyright (c) 2014年 水野 真史. All rights reserved.
//

#import "Utility.h"

@implementation Utility

+ (void)performBlock:(void(^)())block afterDelay:(NSTimeInterval)delay
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), block);
}


@end
