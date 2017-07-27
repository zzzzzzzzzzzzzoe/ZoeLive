//
//  RTMPFrame.h
//  ZoeLive
//
//  Created by mac on 2017/7/19.
//  Copyright © 2017年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RTMPFrame : NSObject
@property (nonatomic, assign) uint64_t timestamp;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSData *header;
@end

@interface RTMPVideoFrame : RTMPFrame

@property (nonatomic, assign) BOOL isKeyFrame;
@property (nonatomic, strong) NSData *sps;
@property (nonatomic, strong) NSData *pps;

@end

@interface RTMPAudioFrame : RTMPFrame

@property (nonatomic, strong) NSData *audioInfo;

@end
