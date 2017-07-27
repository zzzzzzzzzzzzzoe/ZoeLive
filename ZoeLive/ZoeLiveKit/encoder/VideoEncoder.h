//
//  VideoEncoder.h
//  ZoeLive
//
//  Created by mac on 2017/7/19.
//  Copyright © 2017年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZoeLiveAVConfig.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "RTMPFrame.h"
@protocol H264EncoderDelegate <NSObject>

- (void)H264Encoder_call_back_audioFrame:(RTMPVideoFrame *)audionFrame;

@end

@interface VideoEncoder : NSObject
@property (nonatomic, weak) id<H264EncoderDelegate> delegate;
@property (nonatomic, copy) ZoeLiveVideoConfig *videoConfig;
- (void)encodeWithSampleBuffer:(CMSampleBufferRef )sampleBuffer timeStamp:(uint64_t)timeStamp;
- (void)open;
- (void)close;
@end
