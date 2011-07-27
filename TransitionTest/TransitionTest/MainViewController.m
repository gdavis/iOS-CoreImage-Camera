//
//  MainViewController.m
//  TransitionTest
//
//  Created by Grant Davis on 7/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MainViewController.h"
#import "SecondViewController.h"

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1024, 768)];
    self.view.backgroundColor = [UIColor redColor];
    
    transitionView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 1024, 768)];
    transitionView.backgroundColor = [UIColor greenColor];
    transitionView.image = [UIImage imageNamed:@"1024x768-test.png"];
    [self.view addSubview:transitionView];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(0, 200, 100, 40);
    [button addTarget:self action:@selector(nextController) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    transitionIndex = 0;
}

- (void)nextController {    
    
//    transitionIndex++;
//    [UIView beginAnimations:nil context:NULL];
//    [UIView setAnimationDuration:1.0];
//    [UIView setAnimationTransition:110 forView:transitionView cache:YES];
//    [UIView commitAnimations];
    
    CATransition *animation = [CATransition animation];
    [animation setDelegate:self];
    [animation setDuration:1.0f];
    
    CAMediaTimingFunction *tf = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    [animation setTimingFunction:tf];
    [animation setType:@"rippleEffect" ];
    [transitionView.layer addAnimation:animation forKey:NULL];
    
    
    
//    [UIView animateWithDuration:3.0 delay:0 options:110 animations:nil completion:nil];
}


/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
