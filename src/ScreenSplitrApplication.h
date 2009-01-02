//
//  ScreenSplitrApplication.h
//  ScreenSplitr
//
//  Created by Sylvain on 1/1/09.
//  Copyright 2009 Veodia. All rights reserved.
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
- (void)applicationSuspend:(struct __GSEvent*)event;

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) MPTVOutWindow *_tvWindow;
@property (nonatomic, retain) ScreenSplitrScreenView *screenView;
@property (nonatomic, retain) NSTimer* timer;

@end
