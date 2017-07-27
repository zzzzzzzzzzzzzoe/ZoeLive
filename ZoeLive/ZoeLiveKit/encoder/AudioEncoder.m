//
//  AudioEncoder.m
//  ZoeLive
//
//  Created by mac on 2017/7/19.
//  Copyright © 2017年 mac. All rights reserved.
//

#import "AudioEncoder.h"
#import <AudioToolbox/AudioToolbox.h>
#include "aw_alloc.h"

@interface AudioEncoder()
@property (nonatomic, strong) NSData *curFramePcmData;

@property (nonatomic, assign) AudioConverterRef aConverter;
@property (nonatomic, unsafe_unretained) uint32_t aMaxOutputFrameSize;
@end


@implementation AudioEncoder
static OSStatus aacEncodeInputDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData){
    AudioEncoder *AacEncoder = (__bridge AudioEncoder *)inUserData;
    if (AacEncoder.curFramePcmData) {
        ioData->mBuffers[0].mData = (void *)AacEncoder.curFramePcmData.bytes;
        ioData->mBuffers[0].mDataByteSize = (uint32_t)AacEncoder.curFramePcmData.length;
        ioData->mNumberBuffers = 1;
        ioData->mBuffers[0].mNumberChannels = (uint32_t)AacEncoder.audioConfig.channelCount;
        
        return noErr;
    }
    
    return -1;
}

- (void) encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer timeStamp:(uint64_t)timeStamp{
   self.curFramePcmData = [self convertAudioSmapleBufferToPcmData:sampleBuffer];
    AudioBufferList outAudioBufferList = {0};
    outAudioBufferList.mNumberBuffers = 1;
    outAudioBufferList.mBuffers[0].mNumberChannels = (uint32_t)self.audioConfig.channelCount;
    outAudioBufferList.mBuffers[0].mDataByteSize = self.aMaxOutputFrameSize;
    outAudioBufferList.mBuffers[0].mData = malloc(self.aMaxOutputFrameSize);
    
    uint32_t outputDataPacketSize = 1;
    
    OSStatus status = AudioConverterFillComplexBuffer(_aConverter, aacEncodeInputDataProc, (__bridge void * _Nullable)(self), &outputDataPacketSize, &outAudioBufferList, NULL);
    if (status == noErr) {
        NSData *rawAAC = [NSData dataWithBytes: outAudioBufferList.mBuffers[0].mData length:outAudioBufferList.mBuffers[0].mDataByteSize];
        RTMPAudioFrame * frame = [[RTMPAudioFrame alloc]init];
        frame.timestamp = timeStamp;
        frame.data = rawAAC;
        // flv编码音频头 44100 为0x12 0x10
        char *asc = malloc(2);  // 开辟两个长度的字节
        asc[0] = 0x10 | ((4>>1) & 0x3);
        asc[1] = ((4 & 0x1)<<7) | ((1 & 0xF) << 3);
        frame.audioInfo =  [NSData dataWithBytes:asc length:2];
        if (self.delegate && [self.delegate respondsToSelector:@selector(AACEncoder_call_back_audioFrame:)]) {
            [self.delegate AACEncoder_call_back_audioFrame:frame];
        }
        

    }else{
//        [self onErrorWithCode:AWEncoderErrorCodeAudioEncoderFailed des:@"aac 编码错误"];
    }
    CFRelease(sampleBuffer);

}

-(NSData *) convertAudioSmapleBufferToPcmData:(CMSampleBufferRef) audioSample{
    //获取pcm数据大小
    NSInteger audioDataSize = CMSampleBufferGetTotalSampleSize(audioSample);
    
    //分配空间
    int8_t *audio_data = aw_alloc((int32_t)audioDataSize);
    
    //获取CMBlockBufferRef
    //这个结构里面就保存了 PCM数据
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(audioSample);
    //直接将数据copy至我们自己分配的内存中
    CMBlockBufferCopyDataBytes(dataBuffer, 0, audioDataSize, audio_data);
    
    //返回数据
    return [NSData dataWithBytesNoCopy:audio_data length:audioDataSize];
}


-(void)open{
    //创建audio encode converter
    AudioStreamBasicDescription inputAudioDes = {
        .mFormatID = kAudioFormatLinearPCM,
        .mSampleRate = self.audioConfig.sampleRate,
        .mBitsPerChannel = (uint32_t)self.audioConfig.sampleSize,
        .mFramesPerPacket = 1,
        .mBytesPerFrame = 2,
        .mBytesPerPacket = 2,
        .mChannelsPerFrame = (uint32_t)self.audioConfig.channelCount,
        .mFormatFlags = kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsNonInterleaved,
        .mReserved = 0
    };
    
    AudioStreamBasicDescription outputAudioDes = {
        .mChannelsPerFrame = (uint32_t)self.audioConfig.channelCount,
        .mFormatID = kAudioFormatMPEG4AAC,
        0
    };
    
    uint32_t outDesSize = sizeof(outputAudioDes);
    AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &outDesSize, &outputAudioDes);
    OSStatus status = AudioConverterNew(&inputAudioDes, &outputAudioDes, &_aConverter);
    if (status != noErr) {
        NSLog(@"硬编码AAC创建失败");
    }
    
    //设置码率
    uint32_t aBitrate = (uint32_t)self.audioConfig.bitrate;
    uint32_t aBitrateSize = sizeof(aBitrate);
    status = AudioConverterSetProperty(_aConverter, kAudioConverterEncodeBitRate, aBitrateSize, &aBitrate);
    
    //查询最大输出
    uint32_t aMaxOutput = 0;
    uint32_t aMaxOutputSize = sizeof(aMaxOutput);
    AudioConverterGetProperty(_aConverter, kAudioConverterPropertyMaximumOutputPacketSize, &aMaxOutputSize, &aMaxOutput);
    self.aMaxOutputFrameSize = aMaxOutput;
    if (aMaxOutput == 0) {
        NSLog(@"硬编码AAC创建失败");
    }
}

-(void)close{
    AudioConverterDispose(_aConverter);
    _aConverter = nil;
    self.curFramePcmData = nil;
    self.aMaxOutputFrameSize = 0;
}

@end
