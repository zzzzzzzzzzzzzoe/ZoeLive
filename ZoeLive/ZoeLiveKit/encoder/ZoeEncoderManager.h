//
//  ZoeEncoderManager.h
//  ZoeLive
//
//  Created by mac on 2017/7/19.
//  Copyright © 2017年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoEncoder.h"
#import "AudioEncoder.h"
#import "ZoeLiveAVConfig.h"

@interface ZoeEncoderManager : NSObject
@property (nonatomic, readonly, strong) VideoEncoder *videoEncoder;
@property (nonatomic, readonly, strong) AudioEncoder *audioEncoder;
//开启关闭
-(void) openWithAudioConfig:(ZoeLiveAudioConfig *) audioConfig videoConfig:(ZoeLiveVideoConfig *) videoConfig;
-(void) close;
@end
