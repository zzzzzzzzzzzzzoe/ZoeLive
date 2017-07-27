//
//  ZoeLiveCapture.h
//  ZoeLive
//
//  Created by mac on 2017/7/19.
//  Copyright © 2017年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "RtmpStreamConfig.h"
#import "ZoeEncoderManager.h"
#import "RTMPSocket.h"
@protocol ZoeLiveStatusDelegate <NSObject>

- (void)rtmpStatus:(ZoeRtmpState)status;

@end
@class ZoeLiveVideoConfig;
@class ZoeLiveAudioConfig;

@interface ZoeLiveCapture : NSObject<AACEncoderDelegate,RtmpSocketStatusDelegate,H264EncoderDelegate>
- (instancetype)initWithVideoConfig:(ZoeLiveVideoConfig *)videoConfig
                           andAudio:(ZoeLiveAudioConfig *)audioConfig
                            andView:(UIView *)view;

- (BOOL)start;
- (void)stop;
- (void)switchCamera;

@property (nonatomic,strong) RtmpStreamConfig * streamConfig;
@property (nonatomic,strong) ZoeEncoderManager * encoderManager;
@property (nonatomic,strong) RTMPSocket * socket;
@property (nonatomic, weak) id<ZoeLiveStatusDelegate> delegate;

@end
