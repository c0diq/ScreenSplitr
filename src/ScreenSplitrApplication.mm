//
//  ScreenSplitrApplication.m
//  ScreenSplitr
//
//  Created by c0diq on 1/1/09.
//  Copyright 2009 Plutinosoft. All rights reserved.
//


#import "ScreenSplitrApplication.h"
#import "PltFrameBuffer.h"
#import "Platinum.h"
#import "PltFrameServer.h"
#import <Celestial/AVSystemController.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIModalView.h>

typedef enum {
    SS_CLIENT_ON_HOLD,
    SS_CLIENT_ACCEPT,
    SS_CLIENT_REFUSE
} SSNewClientAction;

#define TV_OUTPUT

/* globals */
static PLT_FrameBuffer frame_buffer;
static PLT_UPnP upnp;
static ScreenSplitrApplication* instance = NULL;
PLT_FrameBuffer* frame_buffer_ref = NULL;
static NPT_SharedVariable action_(SS_CLIENT_ON_HOLD);

/* stream request validator */
class StreamValidator : public PLT_StreamValidator
{
public:
    bool OnNewRequestAccept(const NPT_HttpRequestContext& context) {
        NSLog(@"Received stream request from %s", context.GetRemoteAddress().GetIpAddress().ToString().GetChars());
        if (!instance) return false;
        
        {
            NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
            
            NSString* ip_ = [[NSString stringWithFormat:@"%s", context.GetRemoteAddress().GetIpAddress().ToString().GetChars()] retain];
            [instance performSelectorOnMainThread:@selector(askForConnection:) withObject:ip_ waitUntilDone:NO];
            action_.WaitWhileEquals(SS_CLIENT_ON_HOLD, 30000);
            int action = action_.GetValue();
            action_.SetValue(SS_CLIENT_ON_HOLD);    
            
            [pool release];
            
            return (action == SS_CLIENT_ACCEPT);
        }
    }
};

static StreamValidator validator;

/* undocumented classes */
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

static void callback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    NSLog(@"Notification intercepted: %s", CFStringGetCStringPtr(name, kCFStringEncodingUTF8));
    if (instance) {
        if ([UIHardware TVOutCapable]) {
            [instance attachTV];
        } else {
            [instance detachTV];
        }
    }
    return;
}

@implementation ScreenSplitrApplication

@synthesize window;
@synthesize _tvWindow;
@synthesize splashView;
@synthesize screenView;
@synthesize timer;

- (void) applicationDidFinishLaunching: (id) unused {
    // set first global static
    frame_buffer_ref = &frame_buffer;
    instance = self;
    
    // hide status bar
    [UIHardware _setStatusBarHeight: 0.0];
    [self setStatusBarMode:2 duration: 0];
    [self setStatusBarHidden:YES animated:NO];
   	struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
    NSLog(@"Original size: %f, %f, %f, %f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    /* Make sure the rectangle is aligned correctly */
	//rect.origin.x = 0.0f;
	//rect.origin.y = 0.0f;
 
    // create view
    screenView = [[ScreenSplitrScreenView alloc] initWithFrame: rect];
    _tvWindow  = nil;
    
#ifdef TV_OUTPUT
    if ([UIHardware TVOutCapable]) {
        [self attachTV];
    }
#endif
    
	// Create window
	window = [[UIWindow alloc] initWithContentRect: rect];
    //[window setContentView:screenView];
    
    // Splash screen
    splashView = [[UIImageView alloc] initWithFrame:rect];
    splashView.image = [UIImage imageNamed:@"Default.png"];
    [window addSubview: splashView];
    
	// Show window
	[window makeKeyAndVisible];
    
    // register videoout changes (thanks Erica Sadun!)
    CFStringRef notif = CFSTR("com.apple.iapd.videoout.SettingsChanged");
    CFNotificationCenterAddObserver(
                CFNotificationCenterGetDarwinNotifyCenter(), //center
                NULL, // observer
                callback, // callback
                notif, // name
                NULL, // object
                CFNotificationSuspensionBehaviorHold
             ); 

    // start timer to capture screen
    timer = [NSTimer scheduledTimerWithTimeInterval: .3f
                     target: screenView
                     selector: @selector(updateScreen)
                     userInfo: nil
                     repeats: true];
    [self setup];
	[self setApplicationBadge:@"On"];
    
	[self performSelector: @selector(suspendWithAnimation:) withObject: nil afterDelay: 2 ];
}

- (void) askForConnection:(NSString *)ip {
    NSLog(@"AskForConnection");

    UIActionSheet *sheet = [[UIAlertSheet alloc] initWithFrame:
        CGRectMake(0, 240, 320, 240)
    ];
    
    [sheet setTitle:@"Remote View Request"];
    [sheet setBodyText:[NSString stringWithFormat:@"ScreenSplitr\nby Sylvain Rebaud (c0diq)\nsylvain@plutinosoft.com\nhttp://www.plutinosoft.com/\n\nAccept connection from\n%s?", [ip UTF8String]]];
    [sheet addButtonWithTitle:@"Accept"];
    [sheet addButtonWithTitle:@"Reject"];
    [sheet setDelegate: self];
    
    [sheet showInView: splashView];
    //sheet.frame = CGRectMake(0, 240, 320, 240);
    //sheet.origin = CGPointMake(0, 240);
    //[screenView addSubview:sheet];
    [ip release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(int)buttonIndex
{
    NSLog(@"alertSheet with button %d", buttonIndex);
    
    switch (buttonIndex) {
        case 0:
            action_.SetValue(SS_CLIENT_ACCEPT);
            break;

        case 1:
            action_.SetValue(SS_CLIENT_REFUSE);
            break;
    }

    //[actionSheet removeFromSuperview];
    [actionSheet release];
}

- (void)attachTV {
    NSLog(@"Attaching TV");
    
    if (!_tvWindow) {
        MPVideoView *vidView = [[MPVideoView alloc] initWithFrame: [UIHardware fullScreenApplicationContentRect]];
        _tvWindow = [[MPTVOutWindow alloc] initWithVideoView: vidView];  
        [vidView release];

        // vidview size should be updated now
        NSLog(@"vidView size: %f, %f, %f, %f", vidView.bounds.origin.x, vidView.bounds.origin.y, vidView.bounds.size.width, vidView.bounds.size.height);

        [vidView addSubview: screenView];
        [screenView outputToTV: true];
        [_tvWindow makeKeyAndVisible];
    }
}

- (void) detachTV {
    NSLog(@"Detaching TV");
    
    if (_tvWindow) {
        [screenView outputToTV: false];
        [screenView removeFromSuperview];
        [_tvWindow release];
        _tvWindow = nil;
    }
}

- (void) setup {
    // create our UPnP device
    PLT_DeviceHostReference device(new PLT_FrameServer(frame_buffer, 
                                                       NPT_String([[[NSBundle mainBundle] bundlePath] UTF8String]), 
                                                       NPT_String([[[UIDevice currentDevice] name] UTF8String]),
                                                       false,
                                                       NULL,
                                                       8099,
                                                       &validator));
    upnp.AddDevice(device);
    upnp.Start();
    
	[advertiser release];
	advertiser = nil;
    
	advertiser = [Advertiser new];
	[advertiser setDelegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self   
        selector:@selector(routeChange:)   
        name:@"AVSystemController_ActiveAudioRouteDidChangeNotification"  
        object:nil];
   
    /* start bonjour */
	NSError* error;
	if(advertiser == nil || ![advertiser start:device->GetPort()]) {
		NSLog(@"Failed creating upnp server: %@", error);
		return;
	}
	
	//Start advertising to clients, passing nil for the name to tell Bonjour to pick use default name
	if(![advertiser enableBonjourWithDomain:@"local" applicationProtocol:[Advertiser bonjourTypeFromIdentifier:@"http"] name:nil]) {
		NSLog(@"Failed creating bonjour advertiser");
		return;
	}
}

- (void) routeChange: (NSNotification *) notification {
    NSLog(@"routeChange");
    
    id nobj = [notification object];
    if ([nobj isKindOfClass:NSClassFromString(@"AVSystemController")]) {
        NSString* cat = [[nobj routeForCategory:@"Ringtone"] description];
        NSLog(@"%s", [cat UTF8String]);
    
        if (![cat caseInsensitiveCompare:[NSString localizedStringWithFormat:@"%@", @"broadcast"]]) {
        	[self performSelectorOnMainThread:@selector(attachTV) withObject:nil waitUntilDone:NO];
        } else {
            [self performSelectorOnMainThread:@selector(detachTV) withObject:nil waitUntilDone:NO];
        }
    }
}

- (void)suspendWithAnimation:(BOOL)fp8 {
    // Remove splash screen before suspending
    if (splashView) {
        [splashView setHidden: true];
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
    
    [timer invalidate];
    
    // force an empty frame to abort all waiting connections
    frame_buffer_ref->SetNextFrame(NULL, 0);
    
    // abort all upnp stuff / http connections
    upnp.Stop();
}

- (void)dealloc {
    [timer release];
    if (_tvWindow) [_tvWindow release];
    [splashView release];
    [window release];  
    [screenView release];  
    [super dealloc];
}

@end


@implementation ScreenSplitrApplication (AdvertiserDelegate)

- (void) advertiserDidEnableBonjour:(Advertiser*)server withName:(NSString*)string {
	NSLog(@"%s", _cmd);
}

@end

