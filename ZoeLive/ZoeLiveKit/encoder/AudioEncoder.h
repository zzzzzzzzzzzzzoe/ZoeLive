//
//  AudioEncoder.h
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
@protocol AACEncoderDelegate <NSObject>

- (void)AACEncoder_call_back_audioFrame:(RTMPAudioFrame *)videoFrame;

@end
@interface AudioEncoder : NSObject
@property (nonatomic, weak) id<AACEncoderDelegate> delegate;

@property (nonatomic, copy) ZoeLiveAudioConfig *audioConfig;
- (void) encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer timeStamp:(uint64_t)timeStamp;
- (void)open;
- (void)close;
@end
