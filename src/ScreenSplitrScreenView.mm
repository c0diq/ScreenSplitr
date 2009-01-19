//
//  ScreenSplitrScreenView.m
//  ScreenSplitr
//
//  Created by c0diq on 12/31/08.
//  Copyright Plutinosoft 2008. All rights reserved.
//
#import "ImageIO/CGImageDestination.h"
#import "ScreenSplitrScreenView.h"
#import "PltFrameBuffer.h"

#define USE_UIKIT         1
#define USE_COREANIMATION (0)
#define USE_COREGRAPHICS  (!USE_UIKIT && !USE_COREANIMATION)

#if USE_COREANIMATION
#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CALayer.h>
#endif

//#define BENCHMARK

extern "C" NSData *UIImageJPEGRepresentation(UIImage *, float quality);
extern "C" CGImageRef UIGetScreenImage(); 

extern "C" PLT_FrameBuffer* frame_buffer_ref;

@implementation ScreenSplitrScreenView

@synthesize imageView;

- (id)initWithFrame:(CGRect)frame  {
    self = [super initWithFrame:frame];
    if (self != nil) {
        lastValidOrientation = kOrientationVertical;
        tvOutputEnabled = false;
                
        // create the view that will hold the image
        imageView = [[UIImageView alloc] initWithFrame:frame];
        [self addSubview:imageView];
    }
    
    return self;
}

- (void)outputToTV:(bool)enabled {
    tvOutputEnabled = enabled;
}

#ifdef BENCHMARK  
static struct timeval CalculateTimeinterval(struct timeval t) {
    struct timeval now;
    gettimeofday(&now, NULL);

    now.tv_sec -= t.tv_sec;
    now.tv_usec -= t.tv_usec;
    if (now.tv_usec <= -1000000) {
        now.tv_sec--;
        now.tv_usec += 1000000;
    } else if (now.tv_usec >= 1000000) {
        now.tv_sec++;
        now.tv_usec -= 1000000;
    }
    if (now.tv_usec < 0 && now.tv_sec > 0) {
        now.tv_sec--;
        now.tv_usec += 1000000;
    }
    return now;
}
#endif

- (void)updateScreen {
    //NSLog(@"updateScreen");
    
    // check to see if we plugged in a cable
    // and if size of view got updated
    UIView* superview = [self superview];
    if (superview) {
        int orientation = [self getOrientation];
        if (orientation == kOrientationHorizontalLeft || orientation == kOrientationHorizontalRight) {
            self.frame = CGRectMake(superview.frame.origin.x+30, superview.frame.origin.y+80, superview.frame.size.width-60, superview.frame.size.height-160);
        } else {
            self.frame = CGRectMake(superview.frame.origin.x+20, superview.frame.origin.y+15, superview.frame.size.width-40, superview.frame.size.height-30);
        }
        //NSLog(@"Superview size: %f, %f, %f, %f", superview.frame.origin.x, superview.frame.origin.y, superview.frame.size.width, superview.frame.size.height);
    }
    
#ifdef BENCHMARK    
    struct timeval now, bench1, bench2;
    gettimeofday(&now, NULL);
#endif
    // only convert to jpeg if we have a connection (net or TV)
    if (frame_buffer_ref->GetNbReaders() > 0 || tvOutputEnabled) {
        CGImageRef screen = UIGetScreenImage();
        UIImage*   image  = [UIImage imageWithCGImage:screen];
        
#ifdef BENCHMARK        
        bench1 = CalculateTimeinterval(now);
        NSLog(@"UIGetScreenImage took %d secs & %d ms", bench1.tv_sec, bench1.tv_usec/1000);
        
        gettimeofday(&now, NULL);
#endif
        // only scale and rotate if we have a view (when connected to TV)
        if (tvOutputEnabled) {
            [self scaleAndRotate:image inRect:self.frame];
        }
        
        if (frame_buffer_ref->GetNbReaders() > 0) {
            NSData *jpg = UIImageJPEGRepresentation(image, 0.90f);
            frame_buffer_ref->SetNextFrame((const NPT_Byte*)jpg.bytes, (NPT_Size)jpg.length);
        }
                
        //[self dumpImage:image];
        CFRelease(screen);
    }
    
#ifdef BENCHMARK    
    bench2 = CalculateTimeinterval(now);
    NSLog(@"rotation took %d secs & %d ms", bench2.tv_sec, bench2.tv_usec/1000);
#endif
}

- (void)scaleAndRotate:(UIImage*)image inRect:(CGRect) rect {
    int orientation = [self getOrientation];
    
    // 'rotate' screen instead of image to calculate scale ratio
    CGSize maxResolution = CGSizeMake(rect.size.width, rect.size.height);
    if (orientation == kOrientationHorizontalLeft || orientation == kOrientationHorizontalRight) {
        maxResolution = CGSizeMake(rect.size.height, rect.size.width);
    }
    //NSLog(@"MaxResolution: %f, %f", maxResolution.width, maxResolution.height);
	
	float width  = image.size.width;
	float height = image.size.height;
	CGRect bounds = CGRectMake(0, 0, width, height);
	if (width != maxResolution.width || height != maxResolution.height) {
		float ratio = width/height;
		if (ratio > 1) {
			bounds.size.width = maxResolution.width;
			bounds.size.height = bounds.size.width / ratio;
		}
		else {
			bounds.size.height = maxResolution.height;
			bounds.size.width = bounds.size.height * ratio;
		}
	}
    
    //NSLog(@"Center: %f, %f", rect.size.width/2, rect.size.height/2);
    [imageView setCenter: CGPointMake(rect.size.width/2, rect.size.height/2)];
    //NSLog(@"Bounds: %f, %f", bounds.size.width, bounds.size.height);
    [imageView setBounds: bounds];
    
	switch(orientation) {
		case kOrientationVertical:
			[imageView setTransform: CGAffineTransformIdentity];
			break;
			
		case kOrientationVerticalUpsideDown:
			[imageView setTransform: CGAffineTransformMakeRotation(M_PI)];
			break;
			
		case kOrientationHorizontalLeft:
			[imageView setTransform: CGAffineTransformMakeRotation(3.0 * M_PI / 2.0)];
			break;
			
		case kOrientationHorizontalRight:
			[imageView setTransform: CGAffineTransformMakeRotation(M_PI / 2.0)];
			break;
			
		default:
			[NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
			
	}
    [imageView setImage: image];
}

- (int)getOrientation {
    int orientation = [UIHardware deviceOrientation: YES];	
    switch(orientation) {
		case kOrientationVertical:
		case kOrientationVerticalUpsideDown:
		case kOrientationHorizontalLeft:
		case kOrientationHorizontalRight:
			break;		
		default:
            return lastValidOrientation;
	}
    lastValidOrientation = orientation;
    return orientation;
}

- (void)dealloc {   
    [imageView release];
	[super dealloc];
}

@end

