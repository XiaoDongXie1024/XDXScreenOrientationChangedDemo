
## 带有Camera 的View 手动及自动设置屏幕方向汇总

#### 需求：
#### 1. 在一个始终打开Camera的View上，默认以横屏进入，横屏状态下可上下旋转自动变换方向，手动点击按钮切换竖屏，竖屏默认只有Home键向下一种方向。
#### 2. 部分控件横竖屏下的位置差别较大(使用AutoLayout实现) 不在本文介绍,如需帮助请点击[AutoLayout 实现横竖屏位置差别较大的布局]()

#### 注意：带有Camera的View在旋转时需要考虑先旋转屏幕方向再旋转Camera的Video方向，两者并不直接绑定，因此需要我们分开做旋转操作，否则会出现屏幕方向与相机的Video位置不能完全重合。

#### -----------------------------------------

#### GitHub地址(附代码) : [带有Camera 的View 手动及自动设置屏幕方向汇总]()
#### 简书地址   : [带有Camera 的View 手动及自动设置屏幕方向汇总]()
#### 博客地址   : [带有Camera 的View 手动及自动设置屏幕方向汇总]()
#### 掘金地址   : [带有Camera 的View 手动及自动设置屏幕方向汇总]()

#### -----------------------------------------

#### 总体流程：
- 主控制器实现`- (UIInterfaceOrientationMask)supportedInterfaceOrientations`设置支持旋转的方向
- xib中设置每个控件横竖屏下不同的约束
- 通过按钮手动设置屏幕将切换到的方向，并设置相机Video画面的方向
- 设置屏幕不同方向的需要改变的控件的尺寸状态等相关逻辑

##### 1. 在主控制器中首先加载支持屏幕方向的方法

```
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
```

当程序启动后，系统会先调用此方法，在`- (UIInterfaceOrientationMask)supportedInterfaceOrientations`中，通过全局变量flag标识设备支持旋转的方向，这里我们设置如果是竖屏则只支持Home键向下的情况，如果是横屏则支持上下旋转的两种横屏方向，该方法会在屏幕每次旋转时调用。


##### 2. 使用Autolayout 设置xib中控件的布局
如果是要实现横竖屏上的部分控件位置差别比较大可参考一下文章，
如需帮助请点击[AutoLayout 实现横竖屏位置差别较大的布局]()
##### 3. 手动设置屏幕方向
```
- (void)setScreenOrientation:(UIInterfaceOrientation)orientation {
     // m_rotatestate = orientation;   // 本行为我们自己项目中标致旋转方向的全局变量
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
```

当点击转换按钮的时候可通过上面的代码将屏幕手动旋转为竖屏/横屏方向。


##### 4.设置控件的状态
注意：要确保先设置了屏幕方向后再更新部分控件的位置或是状态，不然可能获取部分控件时调用控件的尺寸为上一种屏幕方向时控件的尺寸导致出现异常情况。


#### 注意：
- 因为当APP退出时下次进入会使用上一次保存的横屏或竖屏状态，所以将横竖屏的值保存在数据库
- 当切换横竖屏时，首先设置屏幕方向，**请注意++屏幕方向++和++相机方向++并不直接关联**，所以每次旋转需要分别旋转，然后设置相机Video的方向，即如下代码，相机的方向并不会随着屏幕方向变换而自动切换，所以需要同步进行设置。

```
-(void)adjustAVOutputDataOrientation:(AVCaptureVideoOrientation)aOrientation
{
    for(AVCaptureConnection *connection in video_output.connections)
    {
        for(AVCaptureInputPort *port in [connection inputPorts])
        {
            if([[port mediaType] isEqual:AVMediaTypeVideo])
            {
                if([connection isVideoOrientationSupported])
                {
                    [connection setVideoOrientation:aOrientation];
                }
            }
        }
    }
}
```




- 注册`    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(deviceOrientationDidChange:) name: UIDeviceOrientationDidChangeNotification object: nil];` 当方向旋转过以后会调用一下方法，可进行部分逻辑的实现
```
- (void)deviceOrientationDidChange:(NSNotification *)notification {
    //Obtaining the current device orientation
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    NSLog(@"Curent UIInterfaceOrientation is %ld",(long)orientation);
    
    //Ignoring specific orientations
    if (g_isPortraitMode || orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown  || orientation == UIDeviceOrientationPortrait || orientation == UIDeviceOrientationPortraitUpsideDown){
        return;
    }
    if(orientation == UIDeviceOrientationLandscapeLeft)
        NSLog(@"Device Left");
    if(orientation == UIDeviceOrientationLandscapeRight)
        NSLog(@"Device Right");
    [self rotateToInterfaceOrientation:(UIInterfaceOrientation)orientation];
}
```