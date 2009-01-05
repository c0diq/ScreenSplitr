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

@interface ScreenSplitrApplication : UIApplication {
    UIWindow *window;
    MPTVOutWindow *_tvWindow;
    ScreenSplitrScreenView *screenView;
    NSTimer* timer;
}
- (void)deviceOrientationChanged:(struct __GSEvent *)event;
- (void)applicationSuspend:(struct __GSEvent*)event;

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) MPTVOutWindow *_tvWindow;
@property (nonatomic, retain) ScreenSplitrScreenView *screenView;
@property (nonatomic, retain) NSTimer* timer;

@end
