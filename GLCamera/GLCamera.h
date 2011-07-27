//
//  GLCamera.h
//  GLCamera
//
//  Created by Grant Davis on 7/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

@protocol GLCameraDelegate;

@interface GLCamera : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate> {
    AVCaptureVideoPreviewLayer *videoPreviewLayer;
    AVCaptureSession *session;
    AVCaptureConnection *cameraConnection;
    AVCaptureVideoDataOutput *output;
    
}

- (void)createSession;
- (void)startSession;
- (void)stopSession;

@property(nonatomic, assign) id<GLCameraDelegate> delegate;
@property(nonatomic,readonly)AVCaptureSession *session;
@property(nonatomic,readonly)AVCaptureVideoPreviewLayer *videoPreviewLayer;

@end


@protocol GLCameraDelegate
- (void)processNewCameraFrame:(CVImageBufferRef)cameraFrame;
@end