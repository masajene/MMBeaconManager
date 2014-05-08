//
//  MMBeaconManager.h
//  iBeaconManager
//
//  Created by MasashiMizuno on 2014/04/16.
//  Copyright (c) 2014年 水野 真史. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "MMBeaconRegion.h"

/**
 *  iBeaconの状態
 */
typedef enum {
    kMMBeaconMonitoringStatusDisabled, // 無効
    kMMBeaconMonitoringStatusStopped, // 停止
    kMMBeaconMonitoringStatusMonitoring // 監視中
} MMBeaconMonitoringStatus;

// BeaconUUID同時取得数上限
#define kMMBeaconRegionMax 20

@protocol MMBeaconManagerDelegate <NSObject>

@optional
- (void)didUpdatePeripheralState:(CBPeripheralManagerState)state;
- (void)didUpdateAuthorizationStatus:(CLAuthorizationStatus)status;
- (void)didUpdateMonitoringStatus:(MMBeaconMonitoringStatus)status;

- (void)didUpdateRegionEnterOrExit:(MMBeaconRegion *)region;
- (void)didRangeBeacons:(MMBeaconRegion *)region;
@end

@interface MMBeaconManager : NSObject <CBPeripheralManagerDelegate, CLLocationManagerDelegate>

@property (nonatomic) NSMutableArray *regions;
@property (nonatomic, weak) id<MMBeaconManagerDelegate> delegate;

+ (instancetype)sharedManager;
- (void)requestUpdateForStatus;
- (void)startMonitoring;
- (void)stopMonitoring;
- (MMBeaconRegion *)registerRegion:(NSString *)UUIDString identifier:(NSString *)identifier;
- (MMBeaconRegion *)registerRegion:(NSString *)UUIDString major:(CLBeaconMajorValue)major identifier:(NSString *)identifier;
- (MMBeaconRegion *)registerRegion:(NSString *)UUIDString major:(CLBeaconMajorValue)major minor:(CLBeaconMinorValue)minor identifier:(NSString *)identifier;
- (void)unregisterAllRegion;

@end
