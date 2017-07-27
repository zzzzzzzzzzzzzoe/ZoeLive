//
//  ZoeEncoderManager.m
//  ZoeLive
//
//  Created by mac on 2017/7/19.
//  Copyright © 2017年 mac. All rights reserved.
//

#import "ZoeEncoderManager.h"

@interface ZoeEncoderManager()
//编码器
@property (nonatomic, strong) VideoEncoder *videoEncoder;
@property (nonatomic, strong) AudioEncoder *audioEncoder;
@end

@implementation ZoeEncoderManager
-(void) openWithAudioConfig:(ZoeLiveAudioConfig *) audioConfig videoConfig:(ZoeLiveVideoConfig *) videoConfig{

    self.audioEncoder = [[AudioEncoder alloc]init];
    self.videoEncoder = [[VideoEncoder alloc]init];

    self.audioEncoder.audioConfig = audioConfig;
    self.videoEncoder.videoConfig = videoConfig;
    
    [self.audioEncoder open];
    [self.videoEncoder open];
}

-(void)close{
    [self.audioEncoder close];
    [self.videoEncoder close];
    
    self.audioEncoder = nil;
    self.videoEncoder = nil;
    
}
@end
