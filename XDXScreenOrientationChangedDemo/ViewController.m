//
//  ViewController.m
//  XDXScreenOrientationChangedDemo
//
//  Created by 小东邪 on 23/02/2018.
//  Copyright © 2018 小东邪. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

#define kScreenWidth  [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

// Screen Orientataion
bool  g_isPortraitMode;         // Judge current is portrait or landscape
float _screenWidth_Landscape;
float _screenHeight_Landscape;
float _screenWidth_Portrait;
float _screenHeight_Portrait;

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    CGRect s_frame;
}

@property (weak, nonatomic) IBOutlet UIButton               *switchScreenOrientationBtn;
@property (weak, nonatomic) IBOutlet UILabel                *helloLb;
@property (weak, nonatomic) IBOutlet UILabel                *worldLb;

@property (nonatomic, strong) AVCaptureSession              *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer    *captureVideoPreviewLayer;
@property (nonatomic, strong) AVCaptureVideoDataOutput      *captureOutput;

@end

@implementation ViewController

#pragma mark - View LifeCycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Record landscape / Portrait screen size by global var
    [self initScreenSizeParam];
    
    // Recover button state
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isPortraitMode"]) {
        self.switchScreenOrientationBtn.selected = YES;
    }else {
        self.switchScreenOrientationBtn.selected = NO;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(deviceOrientationDidChange:) name: UIDeviceOrientationDidChangeNotification object: nil];
    
    // Init Camera
    [self initCapture];
    
    [self.view bringSubviewToFront:self.switchScreenOrientationBtn];
    [self.view bringSubviewToFront:self.helloLb];
    [self.view bringSubviewToFront:self.worldLb];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (g_isPortraitMode) {
        [self rotateVideo:UIInterfaceOrientationPortrait];
        [self updateViewUIWhenRotatedWithPortraitMode:YES];
    }
}

#pragma mark - Init
- (void)initScreenSizeParam {
    CGFloat screenW = kScreenWidth;
    CGFloat screenH = kScreenHeight;
    
    if (screenW < screenH) {
        screenW = kScreenHeight;
        screenH = kScreenWidth;
    }
    
    _screenWidth_Landscape  = screenW;
    _screenWidth_Portrait   = screenH;
    _screenHeight_Landscape = screenH;
    _screenHeight_Portrait  = screenW;
}

- (void)initCapture {
    // 获取后置摄像头设备
    AVCaptureDevice      *inputDevice   = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // 创建输入数据对象
    AVCaptureDeviceInput *captureInput  = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:nil];
    if (!captureInput) return;
    
    // 创建一个视频输出对象
    _captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_captureOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    NSString     *key           = (NSString *)kCVPixelBufferPixelFormatTypeKey;
    NSNumber     *value         = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    
    [_captureOutput setVideoSettings:videoSettings];
    
    self.captureSession = [[AVCaptureSession alloc] init];
    n
    NSString *preset;
    if (!preset) preset = AVCaptureSessionPreset1920x1080;
    
    if ([_captureSession canSetSessionPreset:preset]) {
        self.captureSession.sessionPreset = preset;
    }else {
        self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    }
    
    if ([self.captureSession canAddInput:captureInput]) {
        [self.captureSession addInput:captureInput];
    }
    if ([self.captureSession canAddOutput:_captureOutput]) {
        [self.captureSession addOutput:_captureOutput];
    }
    
    // 创建视频预览图层
    if (!self.captureVideoPreviewLayer) {
        self.captureVideoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    }
    
    s_frame.origin.x = 0;
    s_frame.origin.y = 0;
    if (g_isPortraitMode) {
        s_frame.size.width  = _screenWidth_Portrait;
        s_frame.size.height = _screenHeight_Portrait;
    }else {
        s_frame.size.width  = _screenWidth_Landscape;
        s_frame.size.height = _screenHeight_Landscape;
    }
    
    self.captureVideoPreviewLayer.frame = s_frame;
    NSLog(@"ViewDidLoad s_frame -- %@",NSStringFromCGRect(s_frame));
    
    self.captureVideoPreviewLayer.videoGravity  = AVLayerVideoGravityResizeAspectFill;
    if([[self.captureVideoPreviewLayer connection] isVideoOrientationSupported]) {
        [self.captureVideoPreviewLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    }
    
    [self.view.layer     addSublayer:self.captureVideoPreviewLayer];
    [self.captureSession startRunning];
}

#pragma mark - Orientation
// Note : The app run the supportedInterfaceOrientations method at the first, then run the ViewDidLoad method. So we set g_isPortraitMode value at there.
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    UIInterfaceOrientationMask screenMode;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isPortraitMode"]) {
        g_isPortraitMode = true;
        screenMode = UIInterfaceOrientationMaskPortrait;
    }else {
        g_isPortraitMode = false;
        screenMode = UIInterfaceOrientationMaskLandscape;
    }
    
    return screenMode;
}

- (void)setScreenOrientation:(UIInterfaceOrientation)orientation {
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = orientation;//这里可以改变旋转的方向
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    //Obtaining the current device orientation
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    NSLog(@"Curent UIInterfaceOrientation is %ld",(long)orientation);
    
    // We can do something after device orientation had changed.
    if(orientation == UIDeviceOrientationLandscapeLeft) {

    }else if(orientation == UIDeviceOrientationLandscapeRight) {

    }else if(orientation == UIDeviceOrientationPortrait) {
        
    }
    
    //Ignoring specific orientations
    if (g_isPortraitMode || orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown  || orientation == UIDeviceOrientationPortrait || orientation == UIDeviceOrientationPortraitUpsideDown){
        return;
    }
    
    // If the current orientation is landscape we need to rotate video
    [self rotateToInterfaceOrientation:(UIInterfaceOrientation)orientation];
}

- (BOOL)rotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if((interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
        [self rotateVideo:interfaceOrientation];
    }else {
        return NO;
    }
    return YES;
}

- (int)rotateVideo:(UIInterfaceOrientation)interfaceOrientation {
    if(_captureSession != NULL) {
        [_captureSession beginConfiguration];
        CALayer *previewViewLayer = [self.view layer];
        NSArray *subviews         = previewViewLayer.sublayers;
        int i = 0;
        while (true) {
            if(i >= [subviews count]) break;
            id layer = [subviews objectAtIndex:i];
            if([layer isKindOfClass:[AVCaptureVideoPreviewLayer class]] == TRUE) {
                [layer setFrame:s_frame];
                
                switch (interfaceOrientation) {
                    case UIInterfaceOrientationPortrait:
                        [[layer connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];
                        [self adjustAVOutputDataOrientation:AVCaptureVideoOrientationPortrait];
                        break;
                    case UIInterfaceOrientationPortraitUpsideDown:
                        [[layer connection] setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
                        [self adjustAVOutputDataOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
                        break;
                    case UIInterfaceOrientationLandscapeLeft:
                        [[layer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
                        [self adjustAVOutputDataOrientation:AVCaptureVideoOrientationLandscapeLeft];
                        break;
                    case UIInterfaceOrientationLandscapeRight:
                        [[layer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
                        [self adjustAVOutputDataOrientation:AVCaptureVideoOrientationLandscapeRight];
                        break;
                        
                    default:
                        break;
                }
                
                break;
            }
            i++;
        }
        
        [_captureSession commitConfiguration];
    }
    else if(![_captureSession isRunning])
    {
        NSLog(@"_captureSession isnot Running when rotate video!");
    }
    return 0;
}

-(void)adjustAVOutputDataOrientation:(AVCaptureVideoOrientation)aOrientation {
    for(AVCaptureConnection *connection in _captureOutput.connections) {
        for(AVCaptureInputPort *port in [connection inputPorts]) {
            if([[port mediaType] isEqual:AVMediaTypeVideo]) {
                if([connection isVideoOrientationSupported]) {
                    [connection setVideoOrientation:aOrientation];
                }
            }
        }
    }
}

// We can adjust some widget state when the orientation will change.
- (void)updateViewUIWhenRotatedWithPortraitMode:(BOOL)isPortraitMode {
    if (isPortraitMode) {
        
    }else {
        
    }
}

#pragma mark - Button Action
- (IBAction)onpressedbuttonSwitchScreenOrientation:(UIButton *)btn {
    btn.selected = !btn.selected;
    
    if(btn.isSelected) {    // Portrait
        g_isPortraitMode = true;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isPortraitMode"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self setScreenOrientation:UIInterfaceOrientationPortrait];
        s_frame = CGRectMake(0, 0, _screenWidth_Portrait, _screenHeight_Portrait);
        [self rotateVideo:UIInterfaceOrientationPortrait];
        
        [self updateViewUIWhenRotatedWithPortraitMode:YES];
        
    }else {  // Landscape
        g_isPortraitMode = false;
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isPortraitMode"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self setScreenOrientation:UIInterfaceOrientationLandscapeRight];
        s_frame = CGRectMake(0, 0, _screenWidth_Landscape, _screenHeight_Landscape);
        [self rotateVideo:UIInterfaceOrientationLandscapeRight];
        
        [self updateViewUIWhenRotatedWithPortraitMode:NO];
    }
    
}

@end
