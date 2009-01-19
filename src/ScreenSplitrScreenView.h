//
//  ScreenSplitrScreenView.h
//  ScreenSplitr
//
//  Created by c0diq on 12/31/08.
//  Copyright Plutinosoft 2008. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface ScreenSplitrScreenView : UIView {
	CALayer*     screenLayer;
    UIImageView* imageView;
    int          lastValidOrientation;
    bool         tvOutputEnabled;
}

- (void)updateScreen;
- (void)scaleAndRotate:(UIImage*)image inRect:(CGRect) rect;
- (id)initWithFrame:(CGRect)aRect;
- (int)getOrientation;
- (void)outputToTV:(bool)enabled;

@property (nonatomic, retain) UIImageView *imageView;
@end

