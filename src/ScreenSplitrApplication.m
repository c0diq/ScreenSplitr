//
//  ScreenSplitrApplication.m
//  ScreenSplitr
//
//  Created by c0diq on 1/1/09.
//  Copyright 2009 Plutinosoft. All rights reserved.
//

#import "ScreenSplitrApplication.h"

#define TV_OUTPUT

@implementation MPTVOutWindow (extended)
- (BOOL)_canExistBeyondSuspension {
    return TRUE;
}
@end

@implementation MPVideoView (extended)
- (void) addSubview: (UIView *) aView {
    [super addSubview:aView]; 
}
@end

@implementation ScreenSplitrApplication

@synthesize window;
@synthesize _tvWindow;
@synthesize splashView;
@synthesize timer;

- (void) applicationDidFinishLaunching: (id) unused {
    [UIHardware _setStatusBarHeight: 0.0];
    [self setStatusBarMode:2 duration: 0];
    [self setStatusBarHidden:YES animated:NO];
    
   	struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
    NSLog(@"Original size: %f, %f, %f, %f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    /* Make sure the rectangle is aligned correctly */
	//rect.origin.x = 0.0f;
	//rect.origin.y = 0.0f;
 
#ifdef TV_OUTPUT
	MPVideoView *vidView = [[MPVideoView alloc] initWithFrame: rect];
    //[vidView toggleScaleMode: YES]; 
    _tvWindow = [[MPTVOutWindow alloc] initWithVideoView: vidView];  
    [vidView release];

    NSLog(@"vidView size: %f, %f, %f, %f", vidView.bounds.origin.x, vidView.bounds.origin.y, vidView.bounds.size.width, vidView.bounds.size.height);

    ScreenSplitrScreenView* screenView = [[ScreenSplitrScreenView alloc] initWithFrame: CGRectMake(vidView.bounds.origin.x,vidView.bounds.origin.y,vidView.bounds.size.width,vidView.bounds.size.height)];
	[vidView addSubview: screenView];
    [screenView release];
	[_tvWindow makeKeyAndVisible];
    
	// Create window
	window = [[UIWindow alloc] initWithContentRect: rect];
#else
    ScreenSplitrScreenView* screenView = [[ScreenSplitrScreenView alloc] initWithFrame: rect];
    
	// Create window
	window = [[UIWindow alloc] initWithContentRect: rect];
    //[window orderFront: self];
    
	// Set up content view
	[window setContentView: screenView];
    [screenView release];
#endif

    // Splash screen
    splashView = [[UIImageView alloc] initWithFrame:rect];
    splashView.image = [UIImage imageNamed:@"Default.png"];
    [window addSubview: splashView];
    
	// Show window
	[window makeKeyAndVisible];

    timer = [NSTimer scheduledTimerWithTimeInterval: .1f
                     target: screenView
                     selector: @selector(updateScreen)
                     userInfo: nil
                     repeats: true];

    //[NSThread detachNewThreadSelector: @selector(run_update_thread:) toTarget:self withObject:self ];

	[self setApplicationBadge:@"On"];
	[self performSelector: @selector(suspendWithAnimation:) withObject:nil afterDelay: 2 ];
}

/*
- (void) run_update_thread:(ScreenSplitrApplication*)sender {
    NSAutoreleasePool*	pool = [ NSAutoreleasePool new ];
    
    while (self.aborted == false) {
		NSLog(@"animate");
        [self.screenView performSelectorOnMainThread:@selector(updateScreen) withObject:nil waitUntilDone:YES];
		usleep(200000);    
    }
    
    [pool release];
}*/

- (void)suspendWithAnimation:(BOOL)fp8 {
    // Remove splash screen before suspending
    if (splashView) {
        [splashView removeFromSuperview];
        [splashView release];
    }
    
	NSLog(@"Got suspendWithAnimation:");
	[super suspendWithAnimation:fp8];
}

- (void)deviceOrientationChanged:(struct __GSEvent *)event {
    int newOrientation = [ UIHardware deviceOrientation: YES ];
    
    /* Orientation has changed, do something */
    NSLog(@"Orientation %d", newOrientation);
}

// Overridden to prevent terminate (Allows the app to continue to run in the background)
- (void)applicationSuspend:(struct __GSEvent *)fp8 {
}

- (void)applicationDidResume {
	// On the second launch terminate to turn ScreenSplitr off
	[self terminate];
}

- (void)applicationWillTerminate {
	// Remove the "On" badge from the Insomnia SpringBoard icon
	[self removeApplicationBadge];
}

- (void)dealloc {
    [timer invalidate];
    [timer release];
    [_tvWindow release];
    [window release];
    [super dealloc];
}

@end
