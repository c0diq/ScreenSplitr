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
    BOOL abort;
    BOOL askForConnectionPending;
}

- (void)routeChange:(NSNotification *)notification;
- (void)attachTV;
- (void)detachTV;
- (void)deviceOrientationChanged:(struct __GSEvent *)event;
- (void)applicationSuspend:(struct __GSEvent*)event;
- (void)startNetwork;
- (void)askForConnection:(NSString*)ip;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(int)buttonIndex;

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) MPTVOutWindow *_tvWindow;
@property (nonatomic, retain) UIImageView *splashView;
@property (nonatomic, retain) ScreenSplitrScreenView* screenView;
@property (nonatomic, retain) NSTimer* timer;
@property (nonatomic) BOOL abort;
@property (nonatomic) BOOL askForConnectionPending;

@end

@interface ScreenSplitrAlertView : UIAlertView {
    NSTimer* watchdog;
}

@property (nonatomic, retain) NSTimer* watchdog;

@end
