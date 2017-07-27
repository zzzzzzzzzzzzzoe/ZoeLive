//
//  ZoeLiveCapture.m
//  ZoeLive
//
//  Created by mac on 2017/7/19.
//  Copyright © 2017年 mac. All rights reserved.
//

#import "ZoeLiveCapture.h"
#import <AVFoundation/AVFoundation.h>
#import "ZoeLiveAVConfig.h"

@interface ZoeLiveCapture ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>{
    dispatch_semaphore_t    _lock;

}
@property (nonatomic, strong) ZoeLiveAudioConfig *audioConfig;
@property (nonatomic, strong) ZoeLiveVideoConfig *videoConfig;
@property (nonatomic, assign) BOOL inBackground;
//前后摄像头
@property (nonatomic, strong) AVCaptureDeviceInput *frontCamera;
@property (nonatomic, strong) AVCaptureDeviceInput *backCamera;

//当前使用的视频设备
@property (nonatomic, weak) AVCaptureDeviceInput *videoInputDevice;
//音频设备
@property (nonatomic, strong) AVCaptureDeviceInput *audioInputDevice;

//输出数据接收
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;

//会话
@property (nonatomic, strong) AVCaptureSession *captureSession;

//预览
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) UIView *preview;
@property (nonatomic, assign) BOOL allowSent;
@property (nonatomic, assign) uint64_t timestamp;
@property (nonatomic, assign) BOOL isFirstFrame;
@property (nonatomic, assign) uint64_t currentTimestamp;
@property (nonatomic, strong) dispatch_queue_t encodeSampleQueue;

@end
@implementation ZoeLiveCapture
- (instancetype)initWithVideoConfig:(ZoeLiveVideoConfig *)videoConfig
                           andAudio:(ZoeLiveAudioConfig *)audioConfig
                            andView:(UIView *)view{
    self = [super init];
    if (self) {
        self.videoConfig = videoConfig;
        self.audioConfig = audioConfig;
        _lock = dispatch_semaphore_create(1);
        _preview = [[UIView alloc]init];;
        _preview.frame = [UIScreen mainScreen].bounds;
        _preview.backgroundColor = [UIColor blackColor];
        [view addSubview:_preview];
        [view sendSubviewToBack:_preview];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
            case AVAuthorizationStatusAuthorized:   // 已授权
                NSLog(@"已授权");
                [self onInit];
                break;
            case AVAuthorizationStatusNotDetermined:    // 用户尚未进行允许或者拒绝,
            {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    if (granted) {
                        NSLog(@"已授权");
                        [self onInit];
                    } else {
                        NSLog(@"用户拒绝授权摄像头的使用, 返回上一页, 请打开--> 设置 -- > 隐私 --> 通用等权限设置");
                    }
                }];
            }
                break;
            default:
            {
                NSLog(@"用户尚未授权摄像头的使用权");
            }
                break;
        }

    }
    return self;
}

-(dispatch_queue_t)encodeSampleQueue{
    if (!_encodeSampleQueue) {
        _encodeSampleQueue = dispatch_queue_create("aw.encodesample.queue", DISPATCH_QUEUE_SERIAL);
    }
    return _encodeSampleQueue;
}

- (void)dealloc{
    [self destroyCaptureSession];
}

-(void) willEnterForeground{
    self.inBackground = NO;
}

-(void) didEnterBackground{
    self.inBackground = YES;
}

-(void)switchCamera{
    if ([self.videoInputDevice isEqual: self.frontCamera]) {
        self.videoInputDevice = self.backCamera;
    }else{
        self.videoInputDevice = self.frontCamera;
    }
    
    //更新fps
    [self updateFps: self.videoConfig.fps];
}
-(void)onInit{
    [self createCaptureDevice];
    [self createOutput];
    [self createCaptureSession];
    [self createPreviewLayer];
    
    //更新fps
    [self updateFps: self.videoConfig.fps];
}

-(ZoeEncoderManager *)encoderManager{
    if (!_encoderManager) {
        _encoderManager = [[ZoeEncoderManager alloc] init];
        //设置编码器类型
    }
    return _encoderManager;
}


//初始化视频设备
-(void) createCaptureDevice{
    //创建视频设备
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    //初始化摄像头
    self.frontCamera = [AVCaptureDeviceInput deviceInputWithDevice:videoDevices.firstObject error:nil];
    self.backCamera =[AVCaptureDeviceInput deviceInputWithDevice:videoDevices.lastObject error:nil];
    
    //麦克风
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    self.audioInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    
    self.videoInputDevice = self.frontCamera;
}

//切换摄像头
-(void)setVideoInputDevice:(AVCaptureDeviceInput *)videoInputDevice{
    if ([videoInputDevice isEqual:_videoInputDevice]) {
        return;
    }
    //modifyinput
    [self.captureSession beginConfiguration];
    if (_videoInputDevice) {
        [self.captureSession removeInput:_videoInputDevice];
    }
    if (videoInputDevice) {
        [self.captureSession addInput:videoInputDevice];
    }
    
    [self setVideoOutConfig];
    
    [self.captureSession commitConfiguration];
    
    _videoInputDevice = videoInputDevice;
}

//创建预览
-(void) createPreviewLayer{
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.previewLayer.frame = self.preview.bounds;
    [self.preview.layer addSublayer:self.previewLayer];
}

-(void) setVideoOutConfig{
    for (AVCaptureConnection *conn in self.videoDataOutput.connections) {
        if (conn.isVideoStabilizationSupported) {
            [conn setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeAuto];
        }
        if (conn.isVideoOrientationSupported) {
            [conn setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }
        if (conn.isVideoMirrored) {
            [conn setVideoMirrored: YES];
        }
    }
}

//修改fps

-(void) updateFps:(NSInteger) fps{
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *vDevice in videoDevices) {
        float maxRate = [(AVFrameRateRange *)[vDevice.activeFormat.videoSupportedFrameRateRanges objectAtIndex:0] maxFrameRate];
        if (maxRate >= fps) {
            if ([vDevice lockForConfiguration:NULL]) {
                vDevice.activeVideoMinFrameDuration = CMTimeMake(10, (int)(fps * 10));
                vDevice.activeVideoMaxFrameDuration = vDevice.activeVideoMinFrameDuration;
                [vDevice unlockForConfiguration];
            }
        }
    }
}
//创建会话
-(void) createCaptureSession{
    self.captureSession = [[AVCaptureSession alloc]init];
    
    [self.captureSession beginConfiguration];
    
    if ([self.captureSession canAddInput:self.videoInputDevice]) {
        [self.captureSession addInput:self.videoInputDevice];
    }
    
    if ([self.captureSession canAddInput:self.audioInputDevice]) {
        [self.captureSession addInput:self.audioInputDevice];
    }
    
    if([self.captureSession canAddOutput:self.videoDataOutput]){
        [self.captureSession addOutput:self.videoDataOutput];
        [self setVideoOutConfig];
    }
    
    if([self.captureSession canAddOutput:self.audioDataOutput]){
        [self.captureSession addOutput:self.audioDataOutput];
    }
    
    if (![self.captureSession canSetSessionPreset:self.captureSessionPreset]) {
        @throw [NSException exceptionWithName:@"Not supported captureSessionPreset" reason:[NSString stringWithFormat:@"captureSessionPreset is [%@]", self.captureSessionPreset] userInfo:nil];
    }
    
    self.captureSession.sessionPreset = self.captureSessionPreset;
    
    [self.captureSession commitConfiguration];
    
    [self.captureSession startRunning];
}

-(NSString *)captureSessionPreset{
    NSString *captureSessionPreset = nil;
    if(self.videoConfig.width == 480 && self.videoConfig.height == 640){
        captureSessionPreset = AVCaptureSessionPreset640x480;
    }else if(self.videoConfig.width == 540 && self.videoConfig.height == 960){
        captureSessionPreset = AVCaptureSessionPresetiFrame960x540;
    }else if(self.videoConfig.width == 720 && self.videoConfig.height == 1280){
        captureSessionPreset = AVCaptureSessionPreset1280x720;
    }
    return captureSessionPreset;
}

//销毁会话
-(void) destroyCaptureSession{
    if (self.captureSession) {
        [self.captureSession removeInput:self.audioInputDevice];
        [self.captureSession removeInput:self.videoInputDevice];
        [self.captureSession removeOutput:self.self.videoDataOutput];
        [self.captureSession removeOutput:self.self.audioDataOutput];
    }
    self.captureSession = nil;
}

-(void) createOutput{
    
    dispatch_queue_t captureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.videoDataOutput setSampleBufferDelegate:self queue:captureQueue];
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [self.videoDataOutput setVideoSettings:@{
                                             (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
                                             }];
    self.audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    [self.audioDataOutput setSampleBufferDelegate:self queue:captureQueue];
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    if (_inBackground) {
        return;
    }
    if (self.allowSent) {
        if ([self.videoDataOutput isEqual:captureOutput]) {
            CFRetain(sampleBuffer);
            __weak typeof(self) weakSelf = self;
            dispatch_async(self.encodeSampleQueue, ^{
                __strong typeof(weakSelf) strongself = weakSelf;
                [strongself.encoderManager.videoEncoder encodeWithSampleBuffer:sampleBuffer timeStamp:strongself.currentTimestamp];
                CFRelease(sampleBuffer);
            });
        }
        else if([self.audioDataOutput isEqual:captureOutput]){
            CFRetain(sampleBuffer);
            __weak typeof(self) weakSelf = self;
            dispatch_async(self.encodeSampleQueue, ^{
                __strong typeof(weakSelf) strongself = weakSelf;
                [strongself.encoderManager.audioEncoder encodeSampleBuffer:sampleBuffer timeStamp:strongself.currentTimestamp];
            });
        }
    }
}

- (BOOL)start{
    if (!self.streamConfig.url || self.streamConfig.url.length < 8) {
        NSLog(@"rtmpUrl is nil when start capture");
        return NO;
    }
    
    if (!self.videoConfig && !self.audioConfig) {
        NSLog(@"one of videoConfig and audioConfig must be NON-NULL");
        return NO;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //先开启encoder
        __strong typeof(weakSelf) strongself = weakSelf;

        [strongself.encoderManager openWithAudioConfig:strongself.audioConfig videoConfig:strongself.videoConfig];
        strongself.encoderManager.audioEncoder.delegate = strongself;
        strongself.encoderManager.videoEncoder.delegate = strongself;

        //再打开rtmp
        strongself.socket = [[RTMPSocket alloc] initWithStream:strongself.streamConfig];
        strongself.socket.delegate = strongself;
        [strongself.socket start];
    });

    
    return YES;
}

- (void)stop{
    self.allowSent = NO;
    self.isFirstFrame = NO;
    [self.socket stop];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(rtmpStatus:)]) {
            [self.delegate rtmpStatus:ZoeRtmpState_Stop];
        }
    });
    __weak typeof(self) weakSelf = self;
    dispatch_sync(self.encodeSampleQueue, ^{
        __strong typeof(weakSelf)strongself = weakSelf;
        [strongself.encoderManager close];
    });

}


#pragma mark - AACEncoderDelegate
- (void)AACEncoder_call_back_audioFrame:(RTMPAudioFrame *)audionFrame {
    
    if (self.allowSent) {
        [self.socket sendFrame:audionFrame];
    }
}
- (void)H264Encoder_call_back_audioFrame:(RTMPVideoFrame *)videoFrame{
    if (self.allowSent) {
        [self.socket sendFrame:videoFrame];
    }
}

#pragma mark -- JFRtmpSocketDelegate
- (void)socketStatus:(ZoeRtmpState)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(rtmpStatus:)]) {
            [self.delegate rtmpStatus:status];
        }
    });
    switch (status) {
        case ZoeRtmpState_Ready:
            NSLog(@"准备");
            break;
        case ZoeRtmpState_Pending:
            NSLog(@"链接中");
            break;
        case ZoeRtmpState_Start:
            NSLog(@"已连接");
            if (!self.allowSent) {
                self.timestamp = 0;
                self.isFirstFrame = YES;
                self.allowSent = YES;
            }
            break;
        case ZoeRtmpState_Stop:
            NSLog(@"已断开");
            break;
        case ZoeRtmpState_rror:
            NSLog(@"链接出错");
            self.allowSent = NO;
            self.isFirstFrame = NO;
            break;
        default:
            break;
    }
}

- (uint64_t)currentTimestamp{
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    uint64_t currentts = 0;
    if(_isFirstFrame == true) {
        _timestamp = CACurrentMediaTime()*1000;
        _isFirstFrame = false;
        currentts = 0;
    }
    else {
        currentts = (CACurrentMediaTime()*1000) - _timestamp;
    }
    dispatch_semaphore_signal(_lock);
    return currentts;
}

@end
