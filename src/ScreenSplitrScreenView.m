//
//  ScreenSplitrScreenView.m
//  ScreenSplitr
//
//  Created by c0diq on 12/31/08.
//  Copyright Plutinosoft 2008. All rights reserved.
//

#import "ScreenSplitrScreenView.h"
//#import <UIKit/UIView.h>

//#define USE_COREANIMATION 0
//#define USE_COREGRAPHICS (!USE_COREANIMATION)

#if USE_COREANIMATION
#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CALayer.h>
#endif

CGImageRef UIGetScreenImage();

@implementation ScreenSplitrScreenView

- (id)initWithFrame:(CGRect)frame  {
    self = [super initWithFrame:frame];
    if (self != nil) {
        lastValidOrientation = kOrientationVertical;
    }
    
    return self;
}

- (void)updateScreen {
	[self setNeedsDisplay];
}

// draws the passed image into the passed rect, centered and scaled appropriately.
// note that this method doesn't know anything about the current focus, so the focus must be locked outside this method
- (void)drawImage:(UIImage*)image centeredInRect:(CGRect)inRect
{
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

- (UIImage*)scaleAndRotateImage:(UIImage*)image inRect:(CGRect) rect {
    int orientation = [self getOrientation];
    //NSLog(@"Orientation is %d", orientation);
    
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
	CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), [image CGImage]);
	UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    //NSLog(@"Image after transform: %f, %f", image.size.width, image.size.height);

	UIGraphicsEndImageContext();
	
	return imageCopy;
}

- (void)drawRect:(CGRect)rect {
    CGImageRef screen = UIGetScreenImage();
    UIImage*   image  = [UIImage imageWithCGImage:screen];
    //NSLog(@"Image %f,%f vs Screen %f,%f,%f,%f", image.size.width,image.size.height, rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
    
#ifdef USE_COREANIMATION
	CALayer* _screenLayer = [[CALayer layer] retain];
	[_screenLayer setFrame: self.bounds];
	
	[_screenLayer setContents: image];
	[_screenLayer setOpaque: YES];
	if (screenLayer == nil) {
        [[self layer] addSublayer: _screenLayer];
    } else {
        [[self layer] replaceSublayer: screenLayer with: _screenLayer];
        [screenLayer release];
    }
    screenLayer = _screenLayer;
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

    //[image drawAtPoint: CGPointMake(20,0)];
    //[image drawInRect: rect];
    
    //UIImage *img_scale = [image _imageScaledToSize:newImageSize interpolationQuality:2];
    //[img_scale drawAtPoint: CGPointMake(130,-20)];
    //[self drawImage:image CenteredinRect: rect];

#endif

    CFRelease(screen);
}

- (void)setOrientation:(int)interfaceOrientation {
	CGRect contentRect;
    
	switch (interfaceOrientation) {
		case kOrientationHorizontalLeft:
			self.transform = CGAffineTransformMakeRotation(-3.14159/2);
            // Repositions and resizes the view.
            contentRect = CGRectMake(-80, 80, 480, 320);
            self.bounds = contentRect;
			break;
		case kOrientationHorizontalRight:
			self.transform = CGAffineTransformMakeRotation(3.14159/2);
            // Repositions and resizes the view.
            contentRect = CGRectMake(-80, 80, 480, 320);
			break;
        case kOrientationVertical:
            self.transform = CGAffineTransformIdentity;
            contentRect = CGRectMake(0, 0, 320, 480);

	}
    self.bounds = contentRect;
}

- (void)dealloc {    
    if (screenLayer != nil) {
        [screenLayer removeFromSuperlayer];
        [screenLayer release];
    }
	[super dealloc];
}

@end

