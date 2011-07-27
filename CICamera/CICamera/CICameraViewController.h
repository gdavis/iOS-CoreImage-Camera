//
//  CICameraViewController.h
//  CICamera
//
//  Created by Grant Davis on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreVideo/CoreVideo.h>

@interface CICameraViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate> {
    
    AVCaptureVideoPreviewLayer *previewLayer;
    AVCaptureSession *session;
    AVCaptureStillImageOutput *imageOutput;
    AVCaptureConnection *cameraConnection;
    AVCaptureVideoDataOutput *output;
    UIImageView *imageView;
    CIContext *ciContext;
    
    CALayer *videoLayer;
    BOOL useFilters;
}

- (void)printFilterInfo:(CIFilter*)filter;

@property(nonatomic,readonly)AVCaptureSession *session;
//- (CGAffineTransform)transformForOrientation;

@end
