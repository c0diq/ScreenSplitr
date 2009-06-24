//
//  ScreenSplitrScreenView.h
//  ScreenSplitr
//
//  Created by c0diq on 12/31/08.
//  Copyright Plutinosoft 2008. All rights reserved.
//


#import <UIKit/UIKit.h>

#define kOrientationFlatUp 0
#define kOrientationVertical 1
#define kOrientationVerticalUpsideDown 2
#define kOrientationHorizontalLeft 3
#define kOrientationHorizontalRight 4
#define kOrientationUnknown 5
#define kOrientationFlatDown 6

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

