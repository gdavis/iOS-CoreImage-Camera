//
//  CICameraViewController.m
//  CICamera
//
//  Created by Grant Davis on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CICameraViewController.h"

@implementation CICameraViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle



- (void)loadView {
    NSLog(@"load view");
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1024, 768)];
    self.view.backgroundColor = [UIColor redColor];
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 1024, 768)];
    [self.view addSubview:imageView];
    
//    NSLog(@"Distortion: %@", [CIFilter filterNamesInCategory:kCICategoryDistortionEffect]);
//    NSLog(@"Blurs: %@", [CIFilter filterNamesInCategory:kCICategoryBlur]);
//    NSLog(@"Color effects: %@", [CIFilter filterNamesInCategory:kCICategoryColorEffect]);
//    NSLog(@"Color adjustment: %@", [CIFilter filterNamesInCategory:kCICategoryColorAdjustment]);
    NSLog(@"Built-in effects: %@", [CIFilter filterNamesInCategory:kCICategoryBuiltIn]);
    
    // create a capture session
    session = [[AVCaptureSession alloc] init];
    session.sessionPreset = AVCaptureSessionPresetMedium;
    
    // setup the device and input
    AVCaptureDevice *videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:&error];
    
    if (videoInput) {
        [session addInput:videoInput];
        
        // Create a VideoDataOutput and add it to the session
        AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
        output.alwaysDiscardsLateVideoFrames = YES;
        [session addOutput:output];
        
        // Configure your output.
        dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
        [output setSampleBufferDelegate:self queue:queue];
        dispatch_release(queue);
        
        // Specify the pixel format
        output.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] 
                                                           forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        
        [session startRunning];
    }
    else { 
        // Handle the failure.
        NSLog(@"No camera input available.");
    }
}



- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    // create memory pool for handling our images since we are off the main thread.
    @autoreleasepool {
        
        // Get a CMSampleBuffer's Core Video image buffer for the media data
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
        
        // turn buffer into an image we can manipulate
        CIImage *coreImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
        
        // apply some filters
        CIFilter *hueAdjust = [CIFilter filterWithName:@"CIHueAdjust"];
        [hueAdjust setDefaults];
        [hueAdjust setValue: coreImage forKey:@"inputImage"];
        [hueAdjust setValue: [NSNumber numberWithFloat:2.094] forKey: @"inputAngle"];
        CIImage *result = [hueAdjust valueForKey: @"outputImage"];
        
        CIFilter *invert = [CIFilter filterWithName:@"CIColorInvert"];
        [invert setDefaults];
        [invert setValue:result forKey:@"inputImage"];
        result = invert.outputImage;
        //    NSLog(@"invert input keys: %@",[invert inputKeys]);
        //    NSLog(@"invert output keys: %@",[invert outputKeys]);
        
        // only create one CIContext
        if( ciContext == nil )
            ciContext = [CIContext contextWithOptions:nil];
        
        [ciContext drawImage:result atPoint:CGPointZero fromRect:[result extent]];
        
        CGImageRef finishedImage = [ciContext createCGImage:result fromRect:[result extent]];    
        
        // We display the result on the custom layer. All the display stuff must be done in the main thread because
        // UIKit is no thread safe, and as we are not in the main thread (remember we didn't use the main_queue)
        // we use performSelectorOnMainThread to call our CALayer and tell it to display the CGImage.
        [self.view.layer performSelectorOnMainThread:@selector(setContents:) withObject:(__bridge id)finishedImage waitUntilDone:YES];
        
        CGImageRelease(finishedImage);
    }
}



- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return interfaceOrientation == UIInterfaceOrientationLandscapeRight ? YES : NO;
}

@end
