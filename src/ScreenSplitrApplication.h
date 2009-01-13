//
//  ScreenSplitrApplication.h
//  ScreenSplitr
//
//  Created by c0diq on 1/1/09.
//  Copyright 2009 Plutinosoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ScreenSplitrScreenView.h"
#import "MPTVOutWindow.h"
#import "Bonjour.h"

@interface ScreenSplitrApplication : UIApplication {
    UIWindow *window;
    MPTVOutWindow *_tvWindow;
    UIImageView *splashView;
    NSTimer* timer;
	Advertiser* advertiser;
}
- (void)deviceOrientationChanged:(struct __GSEvent *)event;
- (void)applicationSuspend:(struct __GSEvent*)event;

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) MPTVOutWindow *_tvWindow;
@property (nonatomic, retain) UIImageView *splashView;
@property (nonatomic, retain) NSTimer* timer;

@end
