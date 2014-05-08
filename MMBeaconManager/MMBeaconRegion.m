//
//  MMBeaconRegion.m
//  Info
//
//  Created by MasashiMizuno on 2014/04/18.
//  Copyright (c) 2014年 水野 真史. All rights reserved.
//

#import "MMBeaconRegion.h"

@implementation MMBeaconRegion

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)clearFlags
{
    self.rangingEnabled = NO;
    self.isMonitoring = NO;
    self.hasEntered = NO;
    self.isRanging = NO;
    self.failCount = 0;
    self.beacons = nil;
}


@end
