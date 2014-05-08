//
//  MMBeaconRegion.h
//  Info
//
//  Created by MasashiMizuno on 2014/04/18.
//  Copyright (c) 2014年 水野 真史. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#define MMBeaconRegionFailCountMax   3

@interface MMBeaconRegion : CLBeaconRegion
@property (nonatomic) BOOL rangingEnabled;
@property (nonatomic) BOOL isMonitoring;
@property (nonatomic) BOOL hasEntered;
@property (nonatomic) BOOL isRanging;
@property (nonatomic) NSUInteger failCount;
@property (nonatomic) NSArray *beacons;
- (void)clearFlags;
@end
