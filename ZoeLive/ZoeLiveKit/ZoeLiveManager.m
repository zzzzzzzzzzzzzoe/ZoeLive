//
//  ZoeLiveManager.m
//  ZoeLive
//
//  Created by mac on 2017/7/19.
//  Copyright © 2017年 mac. All rights reserved.
//

#import "ZoeLiveManager.h"
#import "ZoeLiveAVConfig.h"

@interface ZoeLiveManager ()
@end

@implementation ZoeLiveManager

- (instancetype )initWithMainView:(UIView *)view{
    if (self = [super init]) {
        ZoeLiveAudioConfig * audioConfig = [[ZoeLiveAudioConfig alloc]init];
        ZoeLiveVideoConfig * videoConfig = [[ZoeLiveVideoConfig alloc]init];
        videoConfig.orientation = UIInterfaceOrientationPortrait;
        _capture = [[ZoeLiveCapture alloc]initWithVideoConfig:videoConfig andAudio:audioConfig andView:view];
        
    }
    return self;
}

- (BOOL)startLiveWithURL:(NSString *)url{
    _capture.streamConfig = [[RtmpStreamConfig alloc] init];
    _capture.streamConfig.url = url;
  return  [_capture start];
}
- (void)stopLive{
    [_capture stop];
}

- (void)switchCamera{
    [_capture switchCamera];
}
@end
