//
//  ScreenSplitrApplication.h
//  ScreenSplitr
//
//  Created by c0diq on 1/1/09.
//  Copyright 2009 Plutinosoft. All rights reserved.
//

#import "ScreenSplitrScreenView.h"
#import "MPTVOutWindow.h"
#import "Bonjour.h"

@interface ScreenSplitrApplication : UIApplication {
    UIWindow *window;
    MPTVOutWindow *_tvWindow;
    UIImageView *splashView;
    ScreenSplitrScreenView* screenView;
    NSTimer* timer;
	Advertiser* advertiser;
}

- (void)routeChange:(NSNotification *)notification;
- (void)attachTV;
- (void)detachTV;
- (void)deviceOrientationChanged:(struct __GSEvent *)event;
- (void)applicationSuspend:(struct __GSEvent*)event;
- (void)setup;
- (void)askForConnection:(NSString*)ip;
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(int)buttonIndex;

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) MPTVOutWindow *_tvWindow;
@property (nonatomic, retain) UIImageView *splashView;
@property (nonatomic, retain) ScreenSplitrScreenView* screenView;
@property (nonatomic, retain) NSTimer* timer;

@end

@interface UIDevice {
}

+ (UIDevice *)currentDevice;

@property(nonatomic,readonly,retain) NSString    *name;              // e.g. "My iPhone"

@property(nonatomic,readonly,getter=isGeneratingDeviceOrientationNotifications) BOOL generatesDeviceOrientationNotifications;
- (void)beginGeneratingDeviceOrientationNotifications;      // nestable
- (void)endGeneratingDeviceOrientationNotifications;

@end
