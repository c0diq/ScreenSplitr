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

- (id)initWithFrame:(CGRect)frame  {
    self = [super initWithFrame:frame];
    if (self != nil) {
        lastValidOrientation = kOrientationVertical;
                
        // create the view that will hold the image
        imageView = [[UIImageView alloc] initWithFrame:frame];
        [self addSubview:imageView];
        [imageView release];
    }
    
    return self;
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
    
#ifdef BENCHMARK    
    struct timeval now, bench1, bench2;
    gettimeofday(&now, NULL);
#endif
    
    CGImageRef screen = UIGetScreenImage();
    UIImage*   image  = [UIImage imageWithCGImage:screen];

#ifdef BENCHMARK        
    bench1 = CalculateTimeinterval(now);
    NSLog(@"UIGetScreenImage took %d secs & %d ms", bench1.tv_sec, bench1.tv_usec/1000);
    
    gettimeofday(&now, NULL);
#endif

    [self scaleAndRotate:image inRect:self.frame];
    
    NSData *jpg = UIImageJPEGRepresentation(image, 0.90f);
    if (frame_buffer_ref) {
        frame_buffer_ref->SetNextFrame((const NPT_Byte*)jpg.bytes, (NPT_Size)jpg.length);
    }
    
    //[self dumpImage:image];
    CFRelease(screen);
    
#ifdef BENCHMARK    
    bench2 = CalculateTimeinterval(now);
    NSLog(@"rotation took %d secs & %d ms", bench2.tv_sec, bench2.tv_usec/1000);
#endif
    
	//[self setNeedsDisplay];
}


#ifdef DRAW_RECT_IMAGEVIEW
- (void)drawRect:(CGRect)rect {
    NSLog(@"drawRect");
    CGImageRef screen = UIGetScreenImage();
    UIImage*   image  = [UIImage imageWithCGImage:screen];
    
    [self scaleAndRotate:image inRect:self.frame];
    CFRelease(screen);
}
#endif

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

// draws the passed image into the passed rect, centered and scaled appropriately.
// note that this method doesn't know anything about the current focus, so the focus must be locked outside this method
- (void)drawImage:(UIImage*)image centeredInRect:(CGRect)inRect {
		CGRect srcRect = CGRectZero;
		srcRect.size = image.size;

		// create a destination rect scaled to fit inside the frame
		CGRect drawnRect = srcRect;
		if (drawnRect.size.width > inRect.size.width) {
			drawnRect.size.height *= inRect.size.width/drawnRect.size.width;
			drawnRect.size.width = inRect.size.width;
		}

		if (drawnRect.size.height > inRect.size.height) {
			drawnRect.size.width *= inRect.size.height/drawnRect.size.height;
			drawnRect.size.height = inRect.size.height;
		}

		drawnRect.origin = inRect.origin;

		// center it in the frame
		drawnRect.origin.x += (inRect.size.width - drawnRect.size.width)/2;
		drawnRect.origin.y += (inRect.size.height - drawnRect.size.height)/2;

		[image drawInRect:drawnRect];
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
    return orientation;
}

#ifdef DRAW_RECT
- (UIImage*)scaleAndRotateImage:(UIImage*)image inRect:(CGRect) rect {
    int orientation = [self getOrientation];
    //NSLog(@"Orientation is %d", orientation);
    
    // 'rotate' screen instead of image to calculate scale ratio
    CGSize maxResolution = CGSizeMake(rect.size.width, rect.size.height);
    if (orientation == kOrientationHorizontalLeft || orientation == kOrientationHorizontalRight) {
        maxResolution = CGSizeMake(rect.size.height, rect.size.width);
    }
    //NSLog(@"MaxResolution: %f, %f", maxResolution.width, maxResolution.height);
	
	float width = image.size.width;
	float height = image.size.height;
	
	CGAffineTransform transform = CGAffineTransformIdentity;
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
    //NSLog(@"Bounds after scale: %f, %f, %f, %f", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
	
	float scaleRatio = bounds.size.width / width;
    //NSLog(@"ScaleRatio: %f", scaleRatio);
        
	CGSize imageSize = CGSizeMake(image.size.width, image.size.height);
	float boundHeight;
    
	switch(orientation) {
		case kOrientationVertical:
			transform = CGAffineTransformIdentity;
			break;
			
		case kOrientationVerticalUpsideDown:
			transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
			transform = CGAffineTransformRotate(transform, M_PI);
			break;
			
		case kOrientationHorizontalLeft:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
			break;
			
		case kOrientationHorizontalRight:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
			transform = CGAffineTransformRotate(transform, M_PI / 2.0);
			break;
			
		default:
			[NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
			
	}
    //NSLog(@"Bounds after rotation: %f, %f, %f, %f", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);

    lastValidOrientation = orientation;
	
    /* transform */
	UIGraphicsBeginImageContext(bounds.size);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
    if (orientation == kOrientationHorizontalLeft || orientation == kOrientationHorizontalRight) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
	
    CGContextConcatCTM(context, transform);
	CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);
	UIImage *imageCopy = (UIImage*)UIGraphicsGetImageFromCurrentImageContext();
    //NSLog(@"Image after transform: %f, %f", image.size.width, image.size.height);

	UIGraphicsEndImageContext();
	
	return imageCopy;
}

- (void)drawRect:(CGRect)rect {
    //NSLog(@"drawRect");

    //[[UIApplication sharedApplication] _dumpScreenContents: nil ];
    /*UIGraphicsBeginImageContext(self.bounds.size);
    [[self layer] renderInContext:UIGraphicsGetCurrentContext()];
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();*/
    
    CGImageRef screen = UIGetScreenImage();
    UIImage*   image  = [UIImage imageWithCGImage:screen];
    
    /*NSLog(@"Image %f,%f vs Screen %f,%f,%f,%f", 
        image.size.width, image.size.height, 
        rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);*/
    
#if USE_COREANIMATION
	[screenLayer setFrame: self.bounds];
    [screenLayer setContents: (id)screen];  

#elif USE_COREGRAPHICS
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextScaleCTM(context, 1, -1);
	rect.size.height = rect.size.height*-1;
    //CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextDrawImage(context, rect, screen);
    CGContextRestoreGState(context);
#else
    UIImage* new_image = [self scaleAndRotateImage:image inRect:rect];
    [self drawImage:new_image centeredInRect: rect];
#endif

    CFRelease(screen);
}
#endif

- (void)dumpImage:(UIImage*)image {
    char buff[512];

    // Make file name
    snprintf( buff, sizeof(buff), "/tmp/ss_%d.png", (int)1/*[[NSDate date] timeIntervalSince1970] */); 
    CFStringRef path = CFStringCreateWithCString( nil, buff, kCFStringEncodingASCII );
    CFURLRef url = CFURLCreateWithFileSystemPath( nil, path, kCFURLPOSIXPathStyle, 0 );

    // Make kUTTypePNG -> public.png
    CFStringRef type = CFStringCreateWithCString( nil, "public.png", kCFStringEncodingASCII );
    size_t count = 1; 
    CFDictionaryRef options = NULL;

    // Writing
    CGImageDestinationRef dest = CGImageDestinationCreateWithURL(url, type, count, options);
    CGImageDestinationAddImage(dest, image.imageRef, NULL);
    CGImageDestinationFinalize(dest);

    // Release
    CFRelease(dest);
    CFRelease(url);
    CFRelease(type);
}

- (void)dealloc {   
    
    // force an empty frame to abort all waiting connections
    frame_buffer_ref->SetNextFrame(NULL, 0);
 
	[super dealloc];
}

@end

