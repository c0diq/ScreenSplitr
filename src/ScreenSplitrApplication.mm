/*****************************************************************
|
|   ScreenSplitr - ScreenSplitrApplication.mm
|
| Copyright (c) 2004-2009, Plutinosoft, LLC.
| All rights reserved.
| http://www.plutinosoft.com
|
| This program is free software; you can redistribute it and/or
| modify it under the terms of the GNU General Public License
| as published by the Free Software Foundation; either version 2
| of the License, or (at your option) any later version.
| 
| This program is distributed in the hope that it will be useful,
| but WITHOUT ANY WARRANTY; without even the implied warranty of
| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
| GNU General Public License for more details.
|
| You should have received a copy of the GNU General Public License
| along with this program; see the file LICENSE.txt. If not, write to
| the Free Software Foundation, Inc., 
| 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
| http://www.gnu.org/licenses/gpl-2.0.html
|
 ****************************************************************/

#import "ScreenSplitrApplication.h"
#import "PltFrameBuffer.h"
#import "Platinum.h"
#import "PltFrameServer.h"
#import "AVSystemController.h"
#import <Foundation/Foundation.h>
#import "UIHardware.h"

typedef enum {
    SS_CLIENT_ON_HOLD,
    SS_CLIENT_ACCEPT,
    SS_CLIENT_REFUSE
} SSNewClientAction;

#define TV_OUTPUT

/* globals */
static PLT_FrameBuffer frame_buffer;
static NPT_Reference<PLT_FrameServer> frame_server;
static ScreenSplitrApplication* instance = NULL;
PLT_FrameBuffer* frame_buffer_ref = NULL;
NPT_SharedVariable action_(SS_CLIENT_ON_HOLD);

/*----------------------------------------------------------------------
|   NPT_Console::Output
+---------------------------------------------------------------------*/
void
NPT_Console::Output(const char* message)
{
    NSLog(@"%s", message);
}

/*----------------------------------------------------------------------
|   StreamValidator
+---------------------------------------------------------------------*/
class StreamValidator : public PLT_StreamValidator
{
public:
    virtual ~StreamValidator() {}
    bool OnNewRequestAccept(const NPT_HttpRequestContext& context) {
        NSLog(@"Received stream request from %s", 
            context.GetRemoteAddress().GetIpAddress().ToString().GetChars());
        if (!instance) return false;
        
        {
            NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
            
            NSString* ip_ = [[NSString stringWithFormat:@"%s", 
                context.GetRemoteAddress().GetIpAddress().ToString().GetChars()] retain];
            [instance performSelectorOnMainThread:@selector(askForConnection:) 
                                       withObject:ip_ 
                                    waitUntilDone:NO];
            action_.WaitWhileEquals(SS_CLIENT_ON_HOLD, 40000);

            int action = action_.GetValue();
            // reset action_ for next time
            action_.SetValue(SS_CLIENT_ON_HOLD);    
            
            [pool release];
            
            return (action == SS_CLIENT_ACCEPT);
        }
    }
};

StreamValidator validator;

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

/* static callback for videoout changes */
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

/* our own implementation of UIAlertView with a watchdog */
@implementation ScreenSplitrAlertView

@synthesize watchdog;

- (void)cancelWatchdog {
    [watchdog invalidate];
}

- (void)dealloc {
    [watchdog invalidate];
    [watchdog release];
    [super dealloc];
}

@end

/* ScreenSplitrApplication */
@implementation ScreenSplitrApplication

@synthesize window;
@synthesize _tvWindow;
@synthesize splashView;
@synthesize screenView;
@synthesize timer;
@synthesize abort;
@synthesize askForConnectionPending;

- (void) applicationDidFinishLaunching: (id) unused {
    NPT_LogManager::GetDefault().Configure("plist:.level=INFO;.handlers=UdpHandler;.UdpHandler.hostname=239.255.255.100;.UdpHandler.port=7724");
    
    // set first global static
    frame_buffer_ref = &frame_buffer;
    instance = self;
    self.abort = NO;
    self.askForConnectionPending = NO;
    
    // hide status bar
    [UIHardware _setStatusBarHeight: 0.0];
    //[self setStatusBarMode:2 duration: 0];
    [self setStatusBarHidden:YES animated:NO];

    // create view
    struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
    NSLog(@"Original size: %f, %f, %f, %f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    screenView = [[ScreenSplitrScreenView alloc] initWithFrame: rect];
    _tvWindow  = nil;
    
#ifdef TV_OUTPUT
    if ([UIHardware TVOutCapable]) {
        [self attachTV];
    }
#endif
    
	// Create window
    window = [[UIWindow alloc] initWithFrame: rect];
    
    // Splash screen
    splashView = [[UIImageView alloc] initWithFrame:rect];
    splashView.image = [UIImage imageNamed:@"Default.png"];
    [window addSubview: splashView];
    
	// Show window
	[window makeKeyAndVisible];

    // start Server & Bonjour
    [self startNetwork];
    
#ifdef TV_OUTPUT
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
        
    [[NSNotificationCenter defaultCenter] addObserver:self   
        selector:@selector(routeChange:)   
        name:@"AVSystemController_ActiveAudioRouteDidChangeNotification"  
        object:nil];
#endif

    // start timer to capture screen
    timer = [NSTimer scheduledTimerWithTimeInterval: .3f
                     target: screenView
                     selector: @selector(updateScreen)
                     userInfo: nil
                     repeats: true];

    if ([self respondsToSelector:@selector(setApplicationBadgeString:)]) {
        [self setApplicationBadgeString:@"On"];
    } else if ([self respondsToSelector:@selector(setApplicationBadge:)]) {
        [self setApplicationBadge:@"On"];
    }
    
	[self performSelector: @selector(suspendApp) withObject: nil afterDelay: 2];
}

- (void) startNetwork {
    // create our http server that will push frames as mjpeg
    frame_server = new PLT_FrameServer(frame_buffer,
                                       NPT_String([[[UIDevice currentDevice] name] UTF8String]),
                                       NPT_String([[[NSBundle mainBundle] bundlePath] UTF8String]),
                                       "screensplitr",
                                       8099,
                                       &validator);
    frame_server->Start();
    
    // just log to console IPs & port
    NPT_List<NPT_IpAddress> ips;
    PLT_UPnPMessageHelper::GetIPAddresses(ips);
    for (NPT_List<NPT_IpAddress>::Iterator ip = ips.GetFirstItem();
         ip;
         ip++) {
        NSLog(@"Screensplitr listening @ http://%s:%d", 
            (const char*)ip->ToString(), frame_server->GetPort());
    }
    
    // clean up & start bonjour
	[advertiser release];
	advertiser = nil;
    
	advertiser = [Advertiser new];
	[advertiser setDelegate:self];
    
	NSError* error;
	if (advertiser == nil || ![advertiser start:frame_server->GetPort()]) {
		NSLog(@"Failed creating upnp server: %@", error);
		return;
	}
    
    // check if veency is running by trying to bind the port which should fail if in use
    /*NPT_TcpServerSocket socket;
    NPT_IpAddress localhost; localhost.Parse("127.0.0.1");
    NPT_Result result = socket.Bind(NPT_SocketAddress(localhost, 5900), false);
    NSLog(@"Binding to 127.0.0.1:5900 returned %d", result);*/
	
	// Start advertising to bonjour clients
    // passing nil to tell Bonjour to use default name
	if (![advertiser enableBonjourWithDomain:@"local" 
                         applicationProtocol:[Advertiser bonjourTypeFromIdentifier:@"http"] 
                                        name:nil
                                        path:@"/content/home.html"]) {
		NSLog(@"Failed creating bonjour advertiser");
		return;
	}
}

- (void) askForConnection:(NSString *)ip {
    NSLog(@"AskForConnection");
    
    // mark that we're relaunching not to quit but to
    // ask for connection authorization
    self.askForConnectionPending = YES;
    
    // relaunch ourselves so the alert view can be seen
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    NSLog(@"Launching ourselves %s", identifier);
    [[UIApplication sharedApplication] launchApplicationWithIdentifier:identifier suspended:NO];
            
    // create the alertview
    ScreenSplitrAlertView *view = [[ScreenSplitrAlertView alloc] initWithFrame:CGRectMake(0, 240, 320, 240)];
    [view setTitle:@"Remote View Request"];
    [view setMessage:[NSString stringWithFormat:@"\nAccept connection from\n%s?\n\nScreenSplitr\nby c0diq\nc0diq@screensplitr.com\nhttp://www.screensplitr.com\n", [ip UTF8String]]];
    [view addButtonWithTitle:@"Accept"];
    [view addButtonWithTitle:@"Reject"];
    [view setDelegate: self];
    
    // create a watchdog timer to close the alert view after 30 secs
    // if user doesn't answer
	id aSignature;
	id anInvocation;
	aSignature = [self methodSignatureForSelector:@selector(dismissAlert:)];
	anInvocation = [NSInvocation invocationWithMethodSignature:aSignature];
	[anInvocation setSelector:@selector(dismissAlert:)];
	[anInvocation setTarget:self];
    [anInvocation setArgument:&view atIndex:2];

	view.watchdog = [NSTimer scheduledTimerWithTimeInterval:30 
		invocation:anInvocation 
		repeats:NO];
    
    // show alert view
    [view show];
    [ip release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(int)buttonIndex
{
    NSLog(@"alertView with button %d", buttonIndex);
    
    switch (buttonIndex) {
        case 0:
            action_.SetValue(SS_CLIENT_ACCEPT);
            break;

        case 1:
            action_.SetValue(SS_CLIENT_REFUSE);
            break;
    }

    // cancel alert view watchdog
	[alertView performSelector: @selector(cancelWatchdog) withObject: nil afterDelay: 0];
    [alertView release];
    
    // suspend app again now that user has clicked on something
    self.askForConnectionPending = NO;
	[self performSelector: @selector(suspendApp) withObject: nil afterDelay: 0];
}

- (void)dismissAlert:(UIAlertView *)alertView
{
    // watchdog called us, automatically close alert view
    [alertView dismissWithClickedButtonIndex:1 animated:NO];
    action_.SetValue(SS_CLIENT_REFUSE);
    [alertView release];
    
    // suspend app again
    self.askForConnectionPending = NO;
	[self performSelector: @selector(suspendApp) withObject: nil afterDelay: 0];
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

- (void)suspendApp {
    // hide splash screen before suspending
    if (splashView) {
        [splashView setHidden: true];
    }
    
    // Firmware 2.2 vs 3.0 handling
	NSLog(@"Got suspendApp:");
    if ([self respondsToSelector:@selector(suspend)]) {
        [self suspend];
    } else if ([self respondsToSelector:@selector(suspendWithAnimation:)]) {
        [self suspendWithAnimation:NO];
    }
}

- (void)deviceOrientationChanged:(struct __GSEvent *)event {
    int newOrientation = [ UIHardware deviceOrientation: YES ];
    
    /* Orientation has changed, do something */
    NSLog(@"Orientation %d", newOrientation);
}

// Overridden to prevent terminate (Allows the app to continue to run in the background)
- (void)applicationSuspend:(struct __GSEvent *)fp8 {
	NSLog(@"Got applicationSuspend:");
    // only suspend if it's intentional
    if (self.abort) [super applicationSuspend:fp8];
}

- (void)applicationDidResume {
	NSLog(@"Got applicationDidResume:");
    
    // make sure we're not resuming because of pending connection
    // request to display alert view
    if (self.askForConnectionPending == NO) {
        // On the second launch terminate to turn ScreenSplitr off
        self.abort = YES;
        
        // Remove the "On" badge from the ScreenSplitr SpringBoard icon
        if ([self respondsToSelector:@selector(setApplicationBadgeString:)]) {
            [self setApplicationBadgeString:@""];
        } else if ([self respondsToSelector:@selector(removeApplicationBadge)]) {
            [self removeApplicationBadge];
        }
        
        [timer invalidate];
        
        // force an empty frame to abort all waiting connections
        frame_buffer_ref->SetNextFrame(NULL, 0);
        
        // abort all upnp stuff / http connections
        frame_server->Stop();
        
        // suspend for good
        [self performSelector: @selector(suspendApp) withObject: nil afterDelay: 2 ];
    } else {
        [splashView setHidden: false];
    }
}

- (void)applicationWillTerminate {
	NSLog(@"Got applicationWillTerminate:");
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

