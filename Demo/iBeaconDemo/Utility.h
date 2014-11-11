//
//  Utility.h
//  iBeaconDemo
//
//  Created by MasashiMizuno on 2014/04/21.
//  Copyright (c) 2014年 水野 真史. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utility : NSObject

+ (void)performBlock:(void(^)())block afterDelay:(NSTimeInterval)delay;

@end
