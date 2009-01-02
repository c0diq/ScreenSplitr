//
//  ScreenSplitrScreenView.h
//  ScreenSplitr
//
//  Created by Sylvain on 12/31/08.
//  Copyright Veodia 2008. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface ScreenSplitrScreenView : UIView {
	CGImageRef screenImage;
	CALayer   *_screenLayer;
    NSTimer   *timer;
}
@end

