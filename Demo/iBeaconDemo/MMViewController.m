//
//  MMViewController.m
//  iBeaconDemo
//
//  Created by MasashiMizuno on 2014/04/18.
//  Copyright (c) 2014年 水野 真史. All rights reserved.
//

#import "MMViewController.h"
#import <PulsingHaloLayer.h>
#import "MMBeaconManager.h"
#import <SVProgressHUD.h>
#import <AVFoundation/AVFoundation.h>

#import "Utility.h"

// UUID
static NSString * const kProximtyUUID = @"00000000-A4D1-1001-B000-001C4D584872";
// Beacon識別Identifier
static NSString * const kBeaconIdentifier = @"com.example.beacon";


@interface MMViewController () <MMBeaconManagerDelegate>

@property (weak) MMBeaconManager *beaconManager;

@property (strong) NSArray *markers1;
@property (strong) NSArray *markers2;
@property (strong) NSArray *markers3;

@property (nonatomic) BOOL couponCount;


@end

@implementation MMViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"計測中...";
        _couponCount = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _markers1 = @[_devicePosition1_1, _devicePosition1_2, _devicePosition1_3];
    _markers2 = @[_devicePosition2_1, _devicePosition2_2, _devicePosition2_3];
    _markers3 = @[_devicePosition3_1, _devicePosition3_2, _devicePosition3_3];

    // ビーコンマネージャ
    self.beaconManager = [MMBeaconManager sharedManager];
    // Delegateの設定
    [self.beaconManager setDelegate:self];
    // ビーコンの情報を設定
    MMBeaconRegion *region = [self.beaconManager registerRegion:kProximtyUUID identifier:kBeaconIdentifier];
    if (region) {
        region.rangingEnabled = YES;
    }
    // 観測開始
    [self.beaconManager startMonitoring];
    
    // 画面のアニメーション開始
    PulsingHaloLayer *halo = [PulsingHaloLayer layer];
    halo.position = self.view.center;
    [self.view.layer addSublayer:halo];
    
    [self.view bringSubviewToFront:self.beaconView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)playSpeech:(NSString *)message
{
    // AVSpeechSynthesizerを初期化する。
    AVSpeechSynthesizer* speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    
    // AVSpeechUtteranceを読ませたい文字列で初期化する。
    NSString* speakingText = message;
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:speakingText];
    
    // AVSpeechSynthesizerにAVSpeechUtteranceを設定して読んでもらう
    [speechSynthesizer speakUtterance:utterance];
}

#pragma mark -------------------------------------------------------
#pragma mark - MMBeaconManagerDelegate
#pragma mark -------------------------------------------------------

- (void)didUpdatePeripheralState:(CBPeripheralManagerState)state
{
    
}

- (void)didUpdateAuthorizationStatus:(CLAuthorizationStatus)status
{
    
}

- (void)didUpdateMonitoringStatus:(MMBeaconMonitoringStatus)status
{
    
}

// 領域に入った、もしくは出た時に呼ばれる
- (void)didUpdateRegionEnterOrExit:(MMBeaconRegion *)region
{
    NSString *meg = nil;
    
    if (region.hasEntered) {
        NSLog(@"didUpdateRegionEnterOrExit: entered");
        meg = @"いらっしゃいませ！";
    } else {
        NSLog(@"didUpdateRegionEnterOrExit: exit");
        meg = @"ありがとうございました！";
        [self allMarkersHidden:4];
    }
    [SVProgressHUD showSuccessWithStatus:meg];
    [self sendLocalNotificationForMessage:meg];
//    [self playSpeech:meg];
}

- (void)didRangeBeacons:(MMBeaconRegion *)region
{
    CLProximity clp;
    if ([region.beacons count] > 0) {
        for (CLBeacon *b in region.beacons) {
            
            clp = b.proximity;
            
            NSString *couponName;
            if ([b.minor isEqualToNumber:@1]) {
                couponName = @"青色";
            } else if ([b.minor isEqualToNumber:@2]) {
                couponName = @"緑色";
            } else {
                couponName = @"オレンジ色";
            }
            
            if (clp == CLProximityImmediate && self.couponCount) {
                [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"%@クーポンゲット", couponName]];
                self.couponCount = NO;
                
                [Utility performBlock:^{
                    self.couponCount = YES;
                } afterDelay:5.0];
                
            }
            [self refleshLocationMarker:b];
        }
    }
    
}

- (void)refleshLocationMarker:(CLBeacon *)beacon
{
    NSArray *targetMarkers;
    if ([beacon.minor isEqualToNumber:@1]) {
        targetMarkers = self.markers1;
    } else if ([beacon.minor isEqualToNumber:@2]) {
        targetMarkers = self.markers2;
    } else {
        targetMarkers = self.markers3;
    }
    
    [self allMarkersHidden:[beacon.minor integerValue]];
    
    switch (beacon.proximity) {
        case CLProximityUnknown:
            break;
        case CLProximityImmediate:
            [(UIView *)targetMarkers[0] setHidden:NO];
            break;
        case CLProximityNear:
            [(UIView *)targetMarkers[1] setHidden:NO];
            break;
        case CLProximityFar:
            [(UIView *)targetMarkers[2] setHidden:NO];
            break;
        default:
            break;
    }
    
}

- (void)allMarkersHidden:(NSInteger)markerNo
{
    switch (markerNo) {
        case 1:
            for (UIView *marker in self.markers1) {
                marker.hidden = YES;
            }
            break;
        case 2:
            for (UIView *marker in self.markers2) {
                marker.hidden = YES;
            }
            break;
        case 3:
            for (UIView *marker in self.markers3) {
                marker.hidden = YES;
            }
            break;
        case 4: {
            for (UIView *marker in self.markers1) {
                marker.hidden = YES;
            }
            for (UIView *marker in self.markers2) {
                marker.hidden = YES;
            }
            for (UIView *marker in self.markers3) {
                marker.hidden = YES;
            }
        }
    }
}

// loacl通知
- (void)sendLocalNotificationForMessage:(NSString *)message
{
    UILocalNotification *localNotification = [UILocalNotification new];
    localNotification.alertBody = message;
    localNotification.fireDate = [NSDate date];
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
//    [self alertMessage:message];
}

@end
