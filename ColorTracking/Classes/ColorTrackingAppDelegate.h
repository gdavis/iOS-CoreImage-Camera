//
//  ColorTrackingAppDelegate.h
//  ColorTracking
//
//
//  The source code for this application is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 10/7/2010.
//

#import <UIKit/UIKit.h>

@class ColorTrackingViewController;

@interface ColorTrackingAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    ColorTrackingViewController *colorTrackingViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet ColorTrackingViewController *viewController;

@end

