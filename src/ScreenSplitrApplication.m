//
//  ScreenSplitrApplication.m
//  ScreenSplitr
//
//  Created by Sylvain on 1/1/09.
//  Copyright 2009 Veodia. All rights reserved.
//

#import "ScreenSplitrApplication.h"

@implementation MPVideoView (extended)
- (void) addSubview: (UIView *) aView {
    [super addSubview:aView]; 
}
@end

@implementation ScreenSplitrApplication

@synthesize window;
@synthesize _tvWindow;
@synthesize screenView;
@synthesize timer;

- (void) applicationDidFinishLaunching: (id) unused
{		
	screenView = [[ScreenSplitrScreenView alloc] initWithFrame: [UIHardware fullScreenApplicationContentRect]];
	
	MPVideoView *vidView = [[MPVideoView alloc] initWithFrame: [UIHardware fullScreenApplicationContentRect]];  
    _tvWindow = [[MPTVOutWindow alloc] initWithVideoView:vidView];  
	[vidView addSubview:screenView];
    
	[_tvWindow makeKeyAndVisible];
    
	// Create window
	window = [[UIWindow alloc] initWithContentRect: [UIHardware fullScreenApplicationContentRect]];
    
	// Set up content view
	//[window setContentView: screenView];
    
	// Show window
	[window makeKeyAndVisible];
    
    timer = [NSTimer scheduledTimerWithTimeInterval: 0.1f
                target: screenView
                selector: @selector(updateScreen)
                userInfo: nil
                repeats: true];
    
	[self setApplicationBadge:@"On"];
	[self performSelector: @selector(suspendWithAnimation:) withObject:nil afterDelay: 0 ];
}

// Overridden to prevent terminate (Allows the app to continue to run in the background)
- (void)applicationSuspend:(struct __GSEvent *)fp8	{
	
}

- (void)applicationDidResume{
	//On the second launch terminate to turn Insomnia off
	[self terminate];
}

- (void)applicationWillTerminate {
	//Remove the "On" badge from the Insomnia SpringBoard icon
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
