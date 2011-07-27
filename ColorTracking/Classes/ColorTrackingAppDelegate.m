//
//  ColorTrackingAppDelegate.m
//  ColorTracking
//
//
//  The source code for this application is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 10/7/2010.
//

#import "ColorTrackingAppDelegate.h"
#import "ColorTrackingViewController.h"

@implementation ColorTrackingAppDelegate

@synthesize window;
@synthesize viewController;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 
{    
    
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	if (!window) 
	{
		[self release];
		return NO;
	}
	window.backgroundColor = [UIColor blackColor];

	window.autoresizesSubviews = YES;
	window.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	if ([[UIScreen screens] count] > 1)
	{
		UIScreen *externalScreen = nil;
		for (UIScreen *currentScreen in [UIScreen screens])
		{
			if (currentScreen != [UIScreen mainScreen])
			{
				externalScreen = currentScreen;
			}
		}
		
		CGRect externalBounds = [externalScreen bounds];
		UIWindow *externalWindow = [[UIWindow alloc] initWithFrame:externalBounds];
		externalWindow.backgroundColor = [UIColor whiteColor];
		externalWindow.screen = externalScreen;
		colorTrackingViewController = [[ColorTrackingViewController alloc] initWithScreen:externalScreen];
		[window addSubview:colorTrackingViewController.view];
		[externalWindow addSubview:colorTrackingViewController.glView];
		
		[externalWindow makeKeyAndVisible];
		[externalWindow layoutSubviews];	
		NSLog(@"External window detected: %f x %f", externalBounds.size.width, externalBounds.size.height);
	}
	else
	{
		colorTrackingViewController = [[ColorTrackingViewController alloc] initWithScreen:[UIScreen mainScreen]];
		[window addSubview:colorTrackingViewController.view];
	}
	
	[[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    [window makeKeyAndVisible];
	[window layoutSubviews];	

    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
    [colorTrackingViewController release];
    [window release];
    [super dealloc];
}


@end
