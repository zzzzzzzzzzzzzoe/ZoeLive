//
//  ZoeLiveAVConfig.m
//  ZoeLive
//
//  Created by mac on 2017/7/19.
//  Copyright © 2017年 mac. All rights reserved.
//

#import "ZoeLiveAVConfig.h"

@implementation ZoeLiveAudioConfig
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.bitrate = 100000;
        self.channelCount = 1;
        self.sampleSize = 16;
        self.sampleRate = 44100;
    }
    return self;
}



-(id)copyWithZone:(NSZone *)zone{
    ZoeLiveAudioConfig *audioConfig = [[ZoeLiveAudioConfig alloc] init];
    audioConfig.bitrate = self.bitrate;
    audioConfig.channelCount = self.channelCount;
    audioConfig.sampleRate = self.sampleRate;
    audioConfig.sampleSize = self.sampleSize;
    return audioConfig;
}

@end

@interface ZoeLiveVideoConfig()
//推流宽高
@property (nonatomic, unsafe_unretained) NSInteger pushStreamWidth;
@property (nonatomic, unsafe_unretained) NSInteger pushStreamHeight;
@end

@implementation ZoeLiveVideoConfig
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.width = 540;
        self.height = 960;
        self.bitrate = 1000000;
        self.fps = 20;
    }
    return self;
}

-(NSInteger)pushStreamWidth{
    if (UIInterfaceOrientationIsLandscape(self.orientation)) {
        return self.height;
    }
    return self.width;
}

-(NSInteger)pushStreamHeight{
    if (UIInterfaceOrientationIsLandscape(self.orientation)) {
        return self.width;
    }
    return self.height;
}


-(id)copyWithZone:(NSZone *)zone{
    ZoeLiveVideoConfig *videoConfig = [[ZoeLiveVideoConfig alloc] init];
    videoConfig.bitrate = self.bitrate;
    videoConfig.fps = self.fps;
    videoConfig.dataFormat = self.dataFormat;
    videoConfig.orientation = self.orientation;
    videoConfig.width = self.width;
    videoConfig.height = self.height;
    return videoConfig;
}

@end
