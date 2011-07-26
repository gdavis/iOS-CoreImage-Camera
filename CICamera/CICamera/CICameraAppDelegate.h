//
//  CICameraAppDelegate.h
//  CICamera
//
//  Created by Grant Davis on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CICameraViewController;

@interface CICameraAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) CICameraViewController *viewController;

@end
