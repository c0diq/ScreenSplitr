//
//  ScreenSplitrApplication.m
//  ScreenSplitr
//
//  Created by c0diq on 1/1/09.
//  Copyright 2009 Plutinosoft. All rights reserved.
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
    //[UIHardware _setStatusBarHeight: 0.0];
    //[self setStatusBarMode:2 duration: 0];
    
   	struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
	//rect.origin.x = rect.origin.y = 0.0f;
    NSLog(@"Original size: %f, %f, %f, %f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
	MPVideoView *vidView = [[MPVideoView alloc] initWithFrame: rect];
    //[vidView toggleScaleMode: YES];  
	//vidView.backgroundColor = [UIColor blueColor];
    _tvWindow = [[MPTVOutWindow alloc] initWithVideoView: vidView];  

    NSLog(@"vidView size: %f, %f, %f, %f", vidView.bounds.origin.x, vidView.bounds.origin.y, vidView.bounds.size.width, vidView.bounds.size.height);

    screenView = [[ScreenSplitrScreenView alloc] initWithFrame: CGRectMake(vidView.bounds.origin.x,vidView.bounds.origin.y,vidView.bounds.size.width,vidView.bounds.size.height)];
	[vidView addSubview: screenView];
    
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
	[self performSelector: @selector(suspendWithAnimation:) withObject:nil afterDelay: 2 ];
}

/*
- (void)centerView:(UIView*)view {
    // Use the screen bounds to determine the center point of the window's content area.
    CGRect screenBounds = [UIHardware fullScreenApplicationContentRect];
    CGRect bounds = CGRectMake(0, 0, screenBounds.size.height, screenBounds.size.width);
    CGPoint center = CGPointMake(bounds.size.height / 2.0, bounds.size.width / 2.0);

    // Set the center point of the view to the center point of the window's content area.
    //view.center = center;
}

- (void)rotateView:(UIView*)view {
    CGAffineTransform transform = view.transform;
        
    [self centerView: view];
    
    // Rotate the view 90 degrees around its new center point.
    transform = CGAffineTransformRotate(transform, (M_PI / 2.0));
    view.transform = transform;
}*/

- (void)deviceOrientationChanged:(struct __GSEvent *)event {
    int newOrientation = [ UIHardware deviceOrientation: YES ];
    
    /* Orientation has changed, do something */
    NSLog(@"Orientation %d", newOrientation);
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
