//
//  MMAppDelegate.m
//  iBeaconDemo
//
//  Created by MasashiMizuno on 2014/04/18.
//  Copyright (c) 2014年 水野 真史. All rights reserved.
//

#import "MMAppDelegate.h"
#import "MMViewController.h"

@implementation MMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    MMViewController *mv = [[MMViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:mv];    
    [self.window setRootViewController:nav];
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

@end
