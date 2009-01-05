//
//  ScreenSplitrScreenView.h
//  ScreenSplitr
//
//  Created by c0diq on 12/31/08.
//  Copyright Plutinosoft 2008. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface ScreenSplitrScreenView : UIView {
	CALayer     *screenLayer;
    int         lastValidOrientation;
}

- (id)initWithFrame:(CGRect)aRect;
- (int)getOrientation;
- (UIImage*)scaleAndRotateImage:(UIImage*)image inRect:(CGRect) rect;
- (void)drawImage:(UIImage*)image centeredInRect:(CGRect)inRect;

@end

