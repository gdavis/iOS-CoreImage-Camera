//
//  CoreImage_CameraViewController.m
//  CoreImage-Camera
//
//  Created by Grant Davis on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CoreImage_CameraViewController.h"

#define kIsCapturingStillImage @"isCapturingStillImage"

@interface CoreImage_CameraViewController (Private)
- (void)captureImage;

@end

@implementation CoreImage_CameraViewController

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
    
    session = [[AVCaptureSession alloc] init];
    
    session.sessionPreset = AVCaptureSessionPreset1280x720;
    
    AVCaptureDevice *videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:&error];
    
    if (videoInput) {
        [session addInput:videoInput];
        
        // create a still capture output that we can feed to CoreImage
        imageOutput = [[AVCaptureStillImageOutput alloc] init];        
        
        // set the options for the still image output
//        NSMutableDictionary *opts = [[NSMutableDictionary alloc] init];
//        [opts setObject:[NSNumber numberWithUnsignedInt:kCMVideoCodecType_JPEG] forKey:AVVideoCodecKey];
//        [opts setObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
        

        NSDictionary *opts = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:kCMVideoCodecType_JPEG], AVVideoCodecKey,
                              [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey,
                                 nil];
        
        imageOutput.outputSettings = opts;
        
        // add output to session
        [session addOutput:imageOutput];
        

        // grab a reference to the new connection for the output.
        cameraConnection = [imageOutput.connections objectAtIndex:0];
        
        
        [imageOutput addObserver:self forKeyPath:kIsCapturingStillImage options:NSKeyValueObservingOptionNew context:nil];
        
        NSLog(@"formats: %@", imageOutput.availableImageDataCodecTypes);        

        
        [session startRunning];
        [self captureImage];
    }
    else { 
        // Handle the failure.
        NSLog(@"No camera input available.");
    }
}

- (void)captureImage {
    NSLog(@"capturing new image");
    [imageOutput captureStillImageAsynchronouslyFromConnection:cameraConnection
                                             completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                                 if (imageDataSampleBuffer != NULL) {
                                                     NSLog(@"received camera image data");
                                                     NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                                     UIImage *image = [UIImage imageWithData:imageData];
                                                     imageView.image = image;
                                                     
                                                     
                                                 } else if (error) {
                                                     //                                                         id delegate = [self delegate];
                                                     //                                                         if ([delegate respondsToSelector:@selector(captureStillImageFailedWithError:)]) {
                                                     //                                                             [delegate captureStillImageFailedWithError:error];
                                                     //                                                         }
                                                 }
                                             }];
}




- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:kIsCapturingStillImage]) {
        NSLog(@"kIsCapturingStillImage changed to: %@", [change objectForKey:NSKeyValueChangeNewKey]);
//        [self captureImage];
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
