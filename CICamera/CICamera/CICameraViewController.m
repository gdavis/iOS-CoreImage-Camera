//
//  CICameraViewController.m
//  CICamera
//
//  Created by Grant Davis on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CICameraViewController.h"

@implementation CICameraViewController
@synthesize session;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}



float randRange(float low, float high);
float interp(float low,float high, float n);
float clamp(float input, float low, float high);
float modulus(float a, float b);
float degreesInterp(float angle1, float angle2, float n);
float farenheitToCelsius(float f);
float celsiusToFarenheit(float c);
float inchesToCM(float in);
float knotsToMPH(float knots);
float knotsToKPH(float knots);
float distance(float x, float y, float x2, float y2);

float max(float a, float b);
float min(float a, float b);


float TNFSliderFunction(float input);

#define DEGREES_TO_RADIANS(__ANGLE__) ((__ANGLE__) / 180.0 * M_PI)



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
//    NSLog(@"Built-in effects: %@", [CIFilter filterNamesInCategory:kCICategoryBuiltIn]);
    
    
    // only create one CIContext
    if( ciContext == nil )
        ciContext = [CIContext contextWithOptions:nil];
    
    // create a capture session
    session = [[AVCaptureSession alloc] init];
    session.sessionPreset = AVCaptureSessionPreset640x480;
    
    // setup the device and input
    AVCaptureDevice *videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:&error];
    
    if (videoInput) {
        [session addInput:videoInput];
        
        // Create a VideoDataOutput and add it to the session
        output = [[AVCaptureVideoDataOutput alloc] init];
        output.alwaysDiscardsLateVideoFrames = YES;
        [session addOutput:output];
        
        // Configure your output.
        dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
        [output setSampleBufferDelegate:self queue:queue];
        dispatch_release(queue);
        
        cameraConnection = [[output connections] objectAtIndex:0];
        cameraConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        
        videoLayer = [CALayer layer];
        videoLayer.frame = self.view.layer.bounds;
        [self.view.layer addSublayer:videoLayer];
        
//        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
//        gradientLayer.frame = self.view.layer.bounds;
//        gradientLayer.type = kCAGradientLayerAxial;
//        gradientLayer.colors = [NSArray arrayWithObjects:(__bridge id)[[UIColor redColor] CGColor], (__bridge id)[[UIColor yellowColor] CGColor], nil];
//        [self.view.layer addSublayer:gradientLayer];
        
        // Specify the pixel format
        output.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] 
                                                           forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        
        [session startRunning];
        
        useFilters = YES;
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
        CIImage *result = [CIImage imageWithCVPixelBuffer:imageBuffer];
        
        // store final usable image
        CGImageRef finishedImage;
        
        if( useFilters ) {
            // hue
            CIFilter *hueAdjust = [CIFilter filterWithName:@"CIHueAdjust"];
            [hueAdjust setDefaults];
            [hueAdjust setValue:result forKey:@"inputImage"];
            [hueAdjust setValue:[NSNumber numberWithFloat:8.094] forKey: @"inputAngle"];
            result = hueAdjust.outputImage;

            
            // gradient
//            CIFilter *redEye = [CIFilter filterWithName:@"CIRadialGradient"];
//            [redEye setDefaults];
//            [redEye setValue:result forKey:@"inputImage"];
//            [redEye setValue:[NSNumber numberWithInt:100] forKey:@"inputRadius0"];
//            [redEye setValue:[NSNumber numberWithInt:600] forKey:@"inputRadius1"];
//            
//            [redEye setValue:[UIColor colorWithRed:1.f green:0.f blue:0.f alpha:1.f] forKey:@"inputColor0"];
//            [redEye setValue:[UIColor colorWithRed:0.f green:0.f blue:1.f alpha:1.f] forKey:@"inputColor1"];
//            result = redEye.outputImage;
            
//            [self printFilterInfo:redEye];
            
            
            // invert
//            CIFilter *invert = [CIFilter filterWithName:@"CIColorInvert"];
//            [invert setDefaults];
//            [invert setValue:result forKey:@"inputImage"];
//            result = invert.outputImage;
        }
        else {
            // add vibrance
            
        }
        
        finishedImage = [ciContext createCGImage:result fromRect:[result extent]];    
        
        [videoLayer performSelectorOnMainThread:@selector(setContents:) withObject:(__bridge id)finishedImage waitUntilDone:YES];
        
        CGImageRelease(finishedImage);
    }
}

- (void)printFilterInfo:(CIFilter*)filter {
    NSLog(@"\n%@\ninput keys: %@ \noutput keys: %@", filter.name, [filter inputKeys], [filter outputKeys]);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    CATransition *animation = [CATransition animation];
    [animation setDelegate:self];
    [animation setDuration:2.0f];
    CAMediaTimingFunction *tf = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [animation setTimingFunction:tf];
    [animation setType:@"rippleEffect"];
    [videoLayer addAnimation:animation forKey:NULL];
    
    useFilters = !useFilters;
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
    ciContext = nil;
    
    cameraConnection = nil;
    
    [session stopRunning];
    session = nil;
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
//    return interfaceOrientation == UIInterfaceOrientationLandscapeRight || interfaceOrientation == UIInterfaceOrientationLandscapeLeft ? YES : NO;
    return interfaceOrientation == UIInterfaceOrientationLandscapeRight ? YES : NO;
}

// adjust camera orientation 
//-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
//    if(self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft ) 
//        cameraConnection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
//    else if( self.interfaceOrientation == UIInterfaceOrientationLandscapeRight )
//        cameraConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
//}

@end
