//
//  ScreenSplitrScreenView.m
//  ScreenSplitr
//
//  Created by Sylvain on 12/31/08.
//  Copyright Veodia 2008. All rights reserved.
//

#import "ScreenSplitrScreenView.h"

//#define USE_COREANIMATION 1

#if USE_COREANIMATION
#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CALayer.h>
#endif

CGImageRef UIGetScreenImage();

//#define USE_COREGRAPHICS  1

//static CALayer* _screenLayer = nil;

@implementation ScreenSplitrScreenView

- (void)updateScreen {
	[self setNeedsDisplay];
}
/*
- (id)initWithCoder:(NSCoder*)coder {
	if ((self = [super initWithCoder:coder])) {		
		//sharedInstance = self;

		NSLog(@"ScreenSplitrScreenView initWithCoder:");		
        timer = [[NSTimer scheduledTimerWithTimeInterval: 1.f
                target: self
                selector: @selector(updateScreen)
                userInfo: nil
                repeats: true] retain];		
	}
	return self;
}	*/

- (void)drawRect:(CGRect)rect {
    CGImageRef screen = UIGetScreenImage();
    UIImage* image = [UIImage imageWithCGImage:screen];
    
#ifdef USE_COREANIMATION
	CALayer* screenLayer = [[CALayer layer] retain];
	[screenLayer setFrame: self.bounds];
	
	[screenLayer setContents: image];
	[screenLayer setOpaque: YES];
	if (_screenLayer == nil) {
        [[self layer] addSublayer: screenLayer];
    } else {
        [[self layer] replaceSublayer: _screenLayer with: screenLayer];
        [_screenLayer release];
    }
    _screenLayer = screenLayer;
#elif USE_COREGRAPHICS
	CGContextRef ctx = UIGraphicsGetCurrentContext();
    //CGContextScaleCTM(ctx, 1.0, -1.0);
	CGContextDrawImage(ctx, aRect, image.CGImage);
    //CFRelease(ctx);
#else
    [image drawInRect: rect];
#endif

    CFRelease(screen);
}

- (void)dealloc {    
    if (_screenLayer != nil) {
        [_screenLayer removeFromSuperlayer];
        [_screenLayer release];
    }
    //[timer invalidate];
    //[timer release];
	[super dealloc];
}

@end

