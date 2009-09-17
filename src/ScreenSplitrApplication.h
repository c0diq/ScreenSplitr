/*****************************************************************
|
|   ScreenSplitr - ScreenSplitrApplication.h
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

#import "ScreenSplitrScreenView.h"
#import "MPTVOutWindow.h"
#import "Bonjour.h"

@interface ScreenSplitrApplication : UIApplication {
    UIWindow *window;
    MPTVOutWindow *_tvWindow;
    UIImageView *splashView;
    ScreenSplitrScreenView* screenView;
    NSTimer* timer;
	Advertiser* advertiser;
    BOOL abort;
    BOOL askForConnectionPending;
}

- (void)routeChange:(NSNotification *)notification;
- (void)attachTV;
- (void)detachTV;
- (void)deviceOrientationChanged:(struct __GSEvent *)event;
- (void)applicationSuspend:(struct __GSEvent*)event;
- (void)startNetwork;
- (void)askForConnection:(NSString*)ip;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(int)buttonIndex;

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) MPTVOutWindow *_tvWindow;
@property (nonatomic, retain) UIImageView *splashView;
@property (nonatomic, retain) ScreenSplitrScreenView* screenView;
@property (nonatomic, retain) NSTimer* timer;
@property (nonatomic) BOOL abort;
@property (nonatomic) BOOL askForConnectionPending;

@end

@interface ScreenSplitrAlertView : UIAlertView {
    NSTimer* watchdog;
}

@property (nonatomic, retain) NSTimer* watchdog;

@end
