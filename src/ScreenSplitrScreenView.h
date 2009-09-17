/*****************************************************************
|
|   ScreenSplitr - ScreenSplitrScreenView.h
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

