//
//  CoreImage_CameraViewController.h
//  CoreImage-Camera
//
//  Created by Grant Davis on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreVideo/CoreVideo.h>

@interface CoreImage_CameraViewController : UIViewController {
    
    AVCaptureVideoPreviewLayer *previewLayer;
    AVCaptureSession *session;
    AVCaptureStillImageOutput *imageOutput;
    AVCaptureConnection *cameraConnection;
    UIImageView *imageView;
}

@end
