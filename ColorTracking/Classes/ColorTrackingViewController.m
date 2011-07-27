//
//  ColorTrackingViewController.m
//  ColorTracking
//
//
//  The source code for this application is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 10/7/2010.
//

#import "ColorTrackingViewController.h"

// Uniform index.
enum {
    UNIFORM_VIDEOFRAME,
	UNIFORM_INPUTCOLOR,
	UNIFORM_THRESHOLD,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXTUREPOSITON,
    NUM_ATTRIBUTES
};

@implementation ColorTrackingViewController

#define DEBUG

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithScreen:(UIScreen *)newScreenForDisplay;
{
    if ((self = [super initWithNibName:nil bundle:nil])) 
	{
		screenForDisplay = newScreenForDisplay;
		
		NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
		
		[currentDefaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
											[NSNumber numberWithFloat:0.89f], @"thresholdColorR", 
											[NSNumber numberWithFloat:0.78f], @"thresholdColorG", 
											[NSNumber numberWithFloat:0.0f], @"thresholdColorB", 
											[NSNumber numberWithFloat:0.7], @"thresholdSensitivity", 
										   nil]];
		
		thresholdColor[0] = [currentDefaults floatForKey:@"thresholdColorR"];
		thresholdColor[1] = [currentDefaults floatForKey:@"thresholdColorG"];
		thresholdColor[2] = [currentDefaults floatForKey:@"thresholdColorB"];
		displayMode = PASSTHROUGH_VIDEO;
        // Custom initialization
		thresholdSensitivity = [currentDefaults floatForKey:@"thresholdSensitivity"];
		
		rawPositionPixels = (GLubyte *) calloc(FBO_WIDTH * FBO_HEIGHT * 4, sizeof(GLubyte));	
    }
    return self;
}

- (void)loadView 
{
	CGRect applicationFrame = [screenForDisplay applicationFrame];	
	CGRect mainScreenFrame = [[UIScreen mainScreen] applicationFrame];	
	UIView *primaryView = [[UIView alloc] initWithFrame:mainScreenFrame];
	self.view = primaryView;
	[primaryView release];

	glView = [[ColorTrackingGLView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, applicationFrame.size.width, applicationFrame.size.height)];	
	[self.view addSubview:glView];
	[glView release];
	
	[self loadVertexShader:@"DirectDisplayShader" fragmentShader:@"DirectDisplayShader" forProgram:&directDisplayProgram];
	[self loadVertexShader:@"ThresholdShader" fragmentShader:@"ThresholdShader" forProgram:&thresholdProgram];
	[self loadVertexShader:@"PositionShader" fragmentShader:@"PositionShader" forProgram:&positionProgram];

	// Set up the toolbar at the bottom of the screen
	UISegmentedControl *displayModeControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:NSLocalizedString(@"Video", nil), NSLocalizedString(@"Threshold", nil), NSLocalizedString(@"Position", nil), NSLocalizedString(@"Track", nil), nil]];
	displayModeControl.segmentedControlStyle = UISegmentedControlStyleBar;
	displayModeControl.selectedSegmentIndex = 0;
	[displayModeControl addTarget:self action:@selector(handleSwitchOfDisplayMode:) forControlEvents:UIControlEventValueChanged];
	
	UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:displayModeControl];
	displayModeControl.frame = CGRectMake(0.0f, 5.0f, 300.0f, 30.0f);
	
	NSArray *theToolbarItems = [NSArray arrayWithObjects:item, nil];
	
	UIToolbar *lowerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, self.view.frame.size.height - 44.0f, self.view.frame.size.width, 44.0f)];
	lowerToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	lowerToolbar.tintColor = [UIColor blackColor];
	
	[lowerToolbar setItems:theToolbarItems];
	[item release];
	
	[self.view addSubview:lowerToolbar];
	[lowerToolbar release];
	
	// Create the tracking dot
	trackingDot = [[CALayer alloc] init];
	trackingDot.bounds = CGRectMake(0.0f, 0.0f, 40.0f, 40.0f);
	trackingDot.cornerRadius = 20.0f;
	trackingDot.backgroundColor = [[UIColor blueColor] CGColor];
	
	NSMutableDictionary *newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"position",
									   nil];
	
	trackingDot.actions = newActions;
	[newActions release];

	[glView.layer addSublayer:trackingDot];
	trackingDot.position = CGPointMake(100.0f, 100.0f);
	trackingDot.opacity = 0.0f;
	
	camera = [[ColorTrackingCamera alloc] init];
	camera.delegate = self;
	[self cameraHasConnected];
}

- (void)didReceiveMemoryWarning 
{
//    [super didReceiveMemoryWarning];
}

- (void)dealloc 
{
	[trackingDot release];
	free(rawPositionPixels);
	[camera release];
    [super dealloc];
}

#pragma mark -
#pragma mark OpenGL ES 2.0 rendering methods

- (void)drawFrame
{    
    // Replace the implementation of this method to do your own custom drawing.
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };

	static const GLfloat textureVertices[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f,  1.0f,
        0.0f,  0.0f,
    };

/*	static const GLfloat passthroughTextureVertices[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f,  1.0f,
        1.0f,  1.0f,
    };
*/	
//    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
//    glClear(GL_COLOR_BUFFER_BIT);
    
	// Use shader program.
	switch (displayMode)
	{
		case PASSTHROUGH_VIDEO:
		{
			[glView setDisplayFramebuffer];
			glUseProgram(directDisplayProgram);
		}; break;
		case SIMPLE_THRESHOLDING:
		{
			[glView setDisplayFramebuffer];
			glUseProgram(thresholdProgram);
		}; break;
		case POSITION_THRESHOLDING:
		{
			[glView setDisplayFramebuffer];
			glUseProgram(positionProgram);			
		}; break;
		case OBJECT_TRACKING:
		{
			[glView setPositionThresholdFramebuffer];
			glUseProgram(positionProgram);			
		}; break;
	}		

	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, videoFrameTexture);
	
	// Update uniform values
	glUniform1i(uniforms[UNIFORM_VIDEOFRAME], 0);	
	glUniform4f(uniforms[UNIFORM_INPUTCOLOR], thresholdColor[0], thresholdColor[1], thresholdColor[2], 1.0f);
	glUniform1f(uniforms[UNIFORM_THRESHOLD], thresholdSensitivity);
		
	// Update attribute values.
	glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
	glEnableVertexAttribArray(ATTRIB_VERTEX);
	glVertexAttribPointer(ATTRIB_TEXTUREPOSITON, 2, GL_FLOAT, 0, 0, textureVertices);
	glEnableVertexAttribArray(ATTRIB_TEXTUREPOSITON);
	
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	if (displayMode == OBJECT_TRACKING)
	{
//		glGenerateMipmap(GL_TEXTURE_2D);
		
		
		// Grab the current position of the object from the offscreen framebuffer
		glReadPixels(0, 0, FBO_WIDTH, FBO_HEIGHT, GL_RGBA, GL_UNSIGNED_BYTE, rawPositionPixels);
		CGPoint currentTrackingLocation = [self centroidFromTexture:rawPositionPixels];		
		trackingDot.position = CGPointMake(currentTrackingLocation.x * glView.bounds.size.width, currentTrackingLocation.y * glView.bounds.size.height);
		
		[glView setDisplayFramebuffer];
		glUseProgram(directDisplayProgram);

		// Grab the previously rendered texture and feed that into the next level of processing
//		glActiveTexture(GL_TEXTURE0);
//		glBindTexture(GL_TEXTURE_2D, glView.positionRenderTexture);
//		glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
//		glEnableVertexAttribArray(ATTRIB_VERTEX);
//		glVertexAttribPointer(ATTRIB_TEXTUREPOSITON, 2, GL_FLOAT, 0, 0, passthroughTextureVertices);
//		glEnableVertexAttribArray(ATTRIB_TEXTUREPOSITON);

	    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);		
	}
	else
	{
	}
    
    [glView presentFramebuffer];
}

#pragma mark -
#pragma mark OpenGL ES 2.0 setup methods

- (BOOL)loadVertexShader:(NSString *)vertexShaderName fragmentShader:(NSString *)fragmentShaderName forProgram:(GLuint *)programPointer;
{
    GLuint vertexShader, fragShader;
	
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    *programPointer = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:vertexShaderName ofType:@"vsh"];
    if (![self compileShader:&vertexShader type:GL_VERTEX_SHADER file:vertShaderPathname])
    {
        NSLog(@"Failed to compile vertex shader");
        return FALSE;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:fragmentShaderName ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname])
    {
        NSLog(@"Failed to compile fragment shader");
        return FALSE;
    }
    
    // Attach vertex shader to program.
    glAttachShader(*programPointer, vertexShader);
    
    // Attach fragment shader to program.
    glAttachShader(*programPointer, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(*programPointer, ATTRIB_VERTEX, "position");
    glBindAttribLocation(*programPointer, ATTRIB_TEXTUREPOSITON, "inputTextureCoordinate");
    
    // Link program.
    if (![self linkProgram:*programPointer])
    {
        NSLog(@"Failed to link program: %d", *programPointer);
        
        if (vertexShader)
        {
            glDeleteShader(vertexShader);
            vertexShader = 0;
        }
        if (fragShader)
        {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (*programPointer)
        {
            glDeleteProgram(*programPointer);
            *programPointer = 0;
        }
        
        return FALSE;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_VIDEOFRAME] = glGetUniformLocation(*programPointer, "videoFrame");
    uniforms[UNIFORM_INPUTCOLOR] = glGetUniformLocation(*programPointer, "inputColor");
    uniforms[UNIFORM_THRESHOLD] = glGetUniformLocation(*programPointer, "threshold");
    
    // Release vertex and fragment shaders.
    if (vertexShader)
	{
        glDeleteShader(vertexShader);
	}
    if (fragShader)
	{
        glDeleteShader(fragShader);		
	}
    
    return TRUE;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source)
    {
        NSLog(@"Failed to load vertex shader");
        return FALSE;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        glDeleteShader(*shader);
        return FALSE;
    }
    
    return TRUE;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

#pragma mark -
#pragma mark Display mode switching

- (void)handleSwitchOfDisplayMode:(id)sender;
{
	displayMode = [sender selectedSegmentIndex];
	
	if (displayMode == OBJECT_TRACKING)
	{
		trackingDot.opacity = 1.0f;
	}
	else
	{
		trackingDot.opacity = 0.0f;
	}
}

#pragma mark -
#pragma mark Image processing

- (CGPoint)centroidFromTexture:(GLubyte *)pixels;
{
	CGFloat currentXTotal = 0.0f, currentYTotal = 0.0f, currentPixelTotal = 0.0f;
	
	for (NSUInteger currentPixel = 0; currentPixel < (FBO_WIDTH * FBO_HEIGHT); currentPixel++)
	{
		currentYTotal += (CGFloat)pixels[currentPixel * 4] / 255.0f;
		currentXTotal += (CGFloat)pixels[(currentPixel * 4) + 1] / 255.0f;
		currentPixelTotal += (CGFloat)pixels[(currentPixel * 4) + 3] / 255.0f;
	}
	
	return CGPointMake(1.0f - (currentXTotal / currentPixelTotal), currentYTotal / currentPixelTotal);
}

#pragma mark -
#pragma mark ColorTrackingCameraDelegate methods

- (void)cameraHasConnected;
{
//	NSLog(@"Connected to camera");
/*	camera.videoPreviewLayer.frame = self.view.bounds;
	[self.view.layer addSublayer:camera.videoPreviewLayer];*/
}

- (void)processNewCameraFrame:(CVImageBufferRef)cameraFrame;
{
	CVPixelBufferLockBaseAddress(cameraFrame, 0);
	int bufferHeight = CVPixelBufferGetHeight(cameraFrame);
	int bufferWidth = CVPixelBufferGetWidth(cameraFrame);
	
	if (shouldReplaceThresholdColor)
	{
		// Extract a color at the touch point from the raw camera data
		int scaledVideoPointX = round((self.view.bounds.size.width - currentTouchPoint.x) * (CGFloat)bufferHeight / self.view.bounds.size.width);
		int scaledVideoPointY = round(currentTouchPoint.y * (CGFloat)bufferWidth / self.view.bounds.size.height);
		
		unsigned char *rowBase = (unsigned char *)CVPixelBufferGetBaseAddress(cameraFrame);
		int bytesPerRow = CVPixelBufferGetBytesPerRow(cameraFrame);
		unsigned char *pixel = rowBase + (scaledVideoPointX * bytesPerRow) + (scaledVideoPointY * 4);
		
		thresholdColor[0] = (float)pixel[2] / 255.0;
		thresholdColor[1] = (float)pixel[1] / 255.0;
		thresholdColor[2] = (float)pixel[0] / 255.0;
		
		[[NSUserDefaults standardUserDefaults] setFloat:thresholdColor[0] forKey:@"thresholdColorR"];
		[[NSUserDefaults standardUserDefaults] setFloat:thresholdColor[1] forKey:@"thresholdColorG"];
		[[NSUserDefaults standardUserDefaults] setFloat:thresholdColor[2] forKey:@"thresholdColorB"];

		shouldReplaceThresholdColor = NO;
	}

	// Create a new texture from the camera frame data, display that using the shaders
	glGenTextures(1, &videoFrameTexture);
	glBindTexture(GL_TEXTURE_2D, videoFrameTexture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	// This is necessary for non-power-of-two textures
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	
	// Using BGRA extension to pull in video frame data directly
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bufferWidth, bufferHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(cameraFrame));

	[self drawFrame];
	
	glDeleteTextures(1, &videoFrameTexture);

	CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
}


#pragma mark -
#pragma mark Touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	currentTouchPoint = [[touches anyObject] locationInView:self.view];
	shouldReplaceThresholdColor = YES;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
{
	CGPoint movedPoint = [[touches anyObject] locationInView:self.view]; 
	CGFloat distanceMoved = sqrt( (movedPoint.x - currentTouchPoint.x) * (movedPoint.x - currentTouchPoint.x) + (movedPoint.y - currentTouchPoint.y) * (movedPoint.y - currentTouchPoint.y) );

	thresholdSensitivity = distanceMoved / 160.0f;
	[[NSUserDefaults standardUserDefaults] setFloat:thresholdSensitivity forKey:@"thresholdSensitivity"];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event 
{
}

#pragma mark -
#pragma mark Accessors

@synthesize glView;

@end
