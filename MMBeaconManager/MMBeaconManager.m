//
//  MMBeaconManager.m
//  iBeaconManager
//
//  Created by MasashiMizuno on 2014/04/16.
//  Copyright (c) 2014年 水野 真史. All rights reserved.
//

#import "MMBeaconManager.h"

@interface MMBeaconManager ()
@property (nonatomic) CBPeripheralManager *peripheralManager;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) MMBeaconMonitoringStatus monitoringStatus;
@property (nonatomic) BOOL monitoringEnabled;
@property (nonatomic) BOOL isMonitoring;
@end

@implementation MMBeaconManager

// sngleton
+ (instancetype)sharedManager {
    static MMBeaconManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[MMBeaconManager alloc] init];
    });
    
    return _sharedManager;
}

// init
- (instancetype)init {
    self = [super init];
    if (self) {
        // 各種初期化
        _monitoringStatus = kMMBeaconMonitoringStatusDisabled;
        _monitoringEnabled = NO;
        _isMonitoring = NO;
        
        _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
        
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        
        // iOS8 After
        if ([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            // iOS バージョンが 8 以上で、requestAlwaysAuthorization メソッドが
            // 利用できる場合
            
            // 位置情報測位の許可を求めるメッセージを表示する
            [_locationManager requestAlwaysAuthorization];
            //      [self.locationManager requestWhenInUseAuthorization];
        }
        
        _regions = [[NSMutableArray alloc] init];
        
        // フォアグランドになったときのNotification通知の登録
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    return self;
}


#pragma mark applicationDidBecomActive local notification handler.
// フォアグラウンドになった時に呼ばれる
- (void)applicationDidBecomeActive
{
    [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(checkRegionState:) userInfo:nil repeats:NO];
}

- (void)checkRegionState:(NSTimer *)timer
{
    for (MMBeaconRegion *region in self.regions) {
        if (region.isMonitoring) {
            [_locationManager requestStateForRegion:region];
        }
    }
}

- (BOOL)isMonitoringCapable
{
    if (![CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        return NO;
    }
    if (_peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        return NO;
    }
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
        return NO;
    }
    return YES;
}

- (void)startMonitoring
{
    self.monitoringEnabled = YES;
    [self startMonitoringAllRegion];
}

- (void)stopMonitoring
{
    self.monitoringEnabled = NO;
    [self stopMonitoringAllRegion];
}

- (void)startMonitoringAllRegion
{
    if (! self.monitoringEnabled)
        return;
    if (! [self isMonitoringCapable])
        return;
    if (self.isMonitoring) {
        return;
    }
    NSLog(@"Start monitoring");
    for (MMBeaconRegion *region in self.regions) {
        [self startMonitoringRegion:region];
    }
    self.isMonitoring = YES;
    [self updateMonitoringStatus];
}

- (void)startMonitoringRegion:(MMBeaconRegion *)region {
    UIApplication *application = [UIApplication sharedApplication];
    
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (bgTask != UIBackgroundTaskInvalid) {
                [application endBackgroundTask:bgTask];
                bgTask = UIBackgroundTaskInvalid;
            }
        });
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_locationManager startMonitoringForRegion:region];
        region.isMonitoring = YES;
    });
}

- (void)startMonitoringRegionTry:(NSTimer *)timer
{
    [self startMonitoringRegion:(MMBeaconRegion *)timer.userInfo];
}

- (void)stopMonitoringAllRegion
{
    if (! self.isMonitoring) {
        return;
    }
    NSLog(@"Stop monitoring");
    for (MMBeaconRegion *region in self.regions) {
        [self stopMonitoringRegion:region];
    }
    self.isMonitoring = NO;
    [self updateMonitoringStatus];
}

- (void)stopMonitoringRegion:(MMBeaconRegion *)region
{
    [_locationManager stopMonitoringForRegion:region];
    [self stopRanging:region];
    region.isMonitoring = NO;
    if (region.hasEntered) {
        region.hasEntered = NO;
        if ([_delegate respondsToSelector:@selector(didUpdateRegionEnterOrExit:)]) {
            [_delegate didUpdateRegionEnterOrExit:region];
        }
    }
}

- (MMBeaconMonitoringStatus)getUpdatedMonitoringStatus
{
    if (! [self isMonitoringCapable]) {
        return kMMBeaconMonitoringStatusDisabled;
    }
    if (_isMonitoring) {
        return kMMBeaconMonitoringStatusMonitoring;
    } else {
        return kMMBeaconMonitoringStatusStopped;
    }
}

- (void)updateMonitoringStatus
{
    MMBeaconMonitoringStatus currentStatus = self.monitoringStatus;
    MMBeaconMonitoringStatus newStatus = [self getUpdatedMonitoringStatus];
    
    if (currentStatus != newStatus) {
        self.monitoringStatus = newStatus;
        if ([_delegate respondsToSelector:@selector(didUpdateMonitoringStatus:)]) {
            [_delegate didUpdateMonitoringStatus:self.monitoringStatus];
        }
    }
}

- (void)requestUpdateForStatus
{
    if ([_delegate respondsToSelector:@selector(didUpdateMonitoringStatus:)]) {
        [_delegate didUpdateMonitoringStatus:self.monitoringStatus];
    }
    if ([_delegate respondsToSelector:@selector(didUpdatePeripheralState:)]) {
        [_delegate didUpdatePeripheralState:self.peripheralManager.state];
    }
    if ([_delegate respondsToSelector:@selector(didUpdateAuthorizationStatus:)]) {
        [_delegate didUpdateAuthorizationStatus:[CLLocationManager authorizationStatus]];
    }
}

- (void)startRanging:(MMBeaconRegion *)region
{
    NSLog(@"startRanging");
    if (! region.isRanging) {
        [_locationManager startRangingBeaconsInRegion:region];
        region.isRanging = YES;
    }
}

- (void)stopRanging:(MMBeaconRegion *)region
{
    NSLog(@"stopRanging");
    if (region.isRanging) {
        [_locationManager stopRangingBeaconsInRegion:region];
        region.beacons = nil;
        region.isRanging = NO;
    }
}

#pragma mark -
#pragma mark Region management
- (MMBeaconRegion *)registerRegion:(NSString *)UUIDString identifier:(NSString *)identifier
{
    if ([self.regions count] >= kMMBeaconRegionMax) {
        return nil;
    }
    MMBeaconRegion *region = [[MMBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:UUIDString] identifier:identifier];
    [region clearFlags];
    
    if (!region) {
        return nil;
    }
    
    [self.regions addObject:region];
    return region;
}

- (MMBeaconRegion *)registerRegion:(NSString *)UUIDString major:(CLBeaconMajorValue)major identifier:(NSString *)identifier
{
    if ([self.regions count] >= kMMBeaconRegionMax) {
        return nil;
    }
    MMBeaconRegion *region = [[MMBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:UUIDString] major:major identifier:identifier];
    [region clearFlags];
    
    if (!region) {
        return nil;
    }
    
    [self.regions addObject:region];
    return region;
}

- (MMBeaconRegion *)registerRegion:(NSString *)UUIDString major:(CLBeaconMajorValue)major minor:(CLBeaconMinorValue)minor identifier:(NSString *)identifier
{
    if ([self.regions count] >= kMMBeaconRegionMax) {
        return nil;
    }
    MMBeaconRegion *region = [[MMBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:UUIDString] major:major minor:minor identifier:identifier];
    [region clearFlags];
    
    if (!region) {
        return nil;
    }
    
    [self.regions addObject:region];
    return region;
}

- (void)unregisterAllRegion
{
    [self stopMonitoring];
    [self.regions removeAllObjects];
}

- (MMBeaconRegion *)lookupRegion:(CLBeaconRegion *)region
{
    for (MMBeaconRegion *mRegion in _regions) {
        if ([mRegion.proximityUUID.UUIDString isEqualToString:region.proximityUUID.UUIDString] &&
            [mRegion.identifier isEqualToString:region.identifier] &&
            mRegion.major == region.major &&
            mRegion.minor == region.minor) {
            return mRegion;
        }
    }
    return nil;
}

- (void)enterRegion:(CLBeaconRegion *)region
{
    NSLog(@"enterRegion called");
    
    // Lookup MMBeaconRegion.
    MMBeaconRegion *mRegion = [self lookupRegion:region];
    if (! mRegion)
        return;
    
    // Already in the region.
    if (mRegion.hasEntered)
        return;
    
    // When ranging is enabled, start ranging.
    if (mRegion.rangingEnabled)
        [self startRanging:mRegion];
    
    // Mark as entered.
    mRegion.hasEntered = YES;
    if ([_delegate respondsToSelector:@selector(didUpdateRegionEnterOrExit:)]) {
        [_delegate didUpdateRegionEnterOrExit:mRegion];
    }
}

- (void)exitRegion:(CLBeaconRegion *)region
{
    NSLog(@"exitRegion called");
    
    MMBeaconRegion *mRegion = [self lookupRegion:region];
    if (! mRegion)
        return;
    
    if (! mRegion.hasEntered)
        return;
    
    if (mRegion.rangingEnabled)
        [self stopRanging:mRegion];
    
    mRegion.hasEntered = NO;
    if ([_delegate respondsToSelector:@selector(didUpdateRegionEnterOrExit:)]) {
        [_delegate didUpdateRegionEnterOrExit:mRegion];
    }
}

#pragma mark -
#pragma mark CBPeripheralManagerDelegate
- (NSString *)peripheralStateString:(CBPeripheralManagerState)state
{
    switch (state) {
        case CBPeripheralManagerStatePoweredOn:
            return @"On";
        case CBPeripheralManagerStatePoweredOff:
            return @"Off";
        case CBPeripheralManagerStateResetting:
            return @"Resetting";
        case CBPeripheralManagerStateUnauthorized:
            return @"Unauthorized";
        case CBPeripheralManagerStateUnknown:
            return @"Unknown";
        case CBPeripheralManagerStateUnsupported:
            return @"Unsupported";
    }
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSLog(@"peripheralManagerDidUpdateState: %@", [self peripheralStateString:peripheral.state]);
    
    if ([self isMonitoringCapable]) {
        [self startMonitoringAllRegion];
    } else {
        [self stopMonitoringAllRegion];
    }
    
    if ([_delegate respondsToSelector:@selector(didUpdatePeripheralState:)]) {
        [_delegate didUpdatePeripheralState:peripheral.state];
    }
    
    [self updateMonitoringStatus];
}

#pragma mark -
#pragma mark CLLocationManagerDelegate (Responding to Region Events)
- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    NSLog(@"didStartMonitoringForRegion:%@", region.identifier);
    
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        MMBeaconRegion *mBeacon = [self lookupRegion:(CLBeaconRegion *)region];
        if (mBeacon) {
            mBeacon.failCount = 0;
        }
    }
    
    [self.locationManager requestStateForRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        [self enterRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        [self exitRegion:(CLBeaconRegion *)region];
    }
}

- (NSString *)regionStateString:(CLRegionState)state
{
    switch (state) {
        case CLRegionStateInside:
            return @"inside";
        case CLRegionStateOutside:
            return @"outside";
        case CLRegionStateUnknown:
            return @"unknown";
    }
    return @"";
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    NSLog(@"didDetermineState:%@(%@)", [self regionStateString:state], region.identifier);
    
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        switch (state) {
            case CLRegionStateInside:
                [self enterRegion:(CLBeaconRegion *)region];
                break;
            case CLRegionStateOutside:
            case CLRegionStateUnknown:
                [self exitRegion:(CLBeaconRegion *)region];
                break;
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSLog(@"monitoringDidFailForRegion:%@(%@)", region.identifier, error);
    NSLog(@"NSLocationWhenInUseUsageDescription is me sure is set to Info.plist");
    
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        MMBeaconRegion *mRegion = [self lookupRegion:(CLBeaconRegion *)region];
        if (! mRegion)
            return;
        
        [self stopMonitoringRegion:mRegion];
        
        if (mRegion.failCount < MMBeaconRegionFailCountMax) {
            mRegion.failCount++;
            [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(startMonitoringRegionTry:) userInfo:mRegion repeats:NO];
        }
    }
}

#pragma mark CLLocationManagerDelegate (Responding to Ranging Events)
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    MMBeaconRegion *mRegion = [self lookupRegion:region];
    if (! mRegion)
        return;
    
    mRegion.beacons = beacons;
    
    if ([_delegate respondsToSelector:@selector(didRangeBeacons:)]) {
        [_delegate didRangeBeacons:mRegion];
    }
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSLog(@"rangingBeaconsDidFailForRegion:%@(%@)", region.identifier, error);
    
    MMBeaconRegion *mRegion = [self lookupRegion:region];
    if (! mRegion)
        return;
    
    [self stopRanging:mRegion];
}

#pragma mark CLLocationManagerDelegate (Responding to Authorization Changes)
- (NSString *)locationAuthorizationStatusString:(CLAuthorizationStatus)status
{
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            return @"Not determined";
        case kCLAuthorizationStatusRestricted:
            return @"Restricted";
        case kCLAuthorizationStatusDenied:
            return @"Denied";
        case kCLAuthorizationStatusAuthorizedAlways:
            return @"Authorized";
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            return @"";
    }
    return @"";
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog(@"didChangeAuthorizationStatus:%@", [self locationAuthorizationStatusString:status]);
    
    if ([self isMonitoringCapable]) {
        [self startMonitoringAllRegion];
    } else {
        [self stopMonitoringAllRegion];
    }
    
    if ([_delegate respondsToSelector:@selector(didUpdateAuthorizationStatus:)]) {
        [_delegate didUpdateAuthorizationStatus:status];
    }
    
    [self updateMonitoringStatus];
}


@end
