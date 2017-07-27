//
//  VideoEncoder.m
//  ZoeLive
//
//  Created by mac on 2017/7/19.
//  Copyright © 2017年 mac. All rights reserved.
//

#import "VideoEncoder.h"
#import <VideoToolbox/VideoToolbox.h>

@interface VideoEncoder (){
    long    _frameCount;

}
@property (nonatomic, unsafe_unretained) VTCompressionSessionRef vEnSession;
@property (nonatomic, strong) NSData *sps_jf;
@property (nonatomic, strong) NSData *pps_jf;
@end

@implementation VideoEncoder



// 编码一帧图像，使用queue，防止阻塞系统摄像头采集线程
- (void)encodeWithSampleBuffer:(CMSampleBufferRef )sampleBuffer timeStamp:(uint64_t)timeStamp {
        CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
        // pts,必须设置，否则会导致编码出来的数据非常大，原因未知
        _frameCount ++;
        CMTime pts = CMTimeMake(_frameCount, 1000);
        CMTime duration = kCMTimeInvalid;
        NSDictionary *properties = nil;
        
        // 关键帧的最大间隔 设为 帧率的二倍
        if(_frameCount % (int32_t)self.videoConfig.fps  * 2 == 0){
            properties = @{(__bridge NSString *)kVTEncodeFrameOptionKey_ForceKeyFrame: @YES};
        }
        NSNumber *timeNumber = @(timeStamp);
        VTEncodeInfoFlags flags;
        
        // 送入编码器编码
        OSStatus statusCode = VTCompressionSessionEncodeFrame(_vEnSession,
                                                              imageBuffer,
                                                              pts, duration,
                                                              (__bridge CFDictionaryRef)properties, (__bridge_retained void *)timeNumber, &flags);
        
        if (statusCode != noErr) {
            NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)statusCode);
            
            [self close];
            return;
        }
    
}

// 编码回调, 系统每完成一帧编码后, 就会异步调用该方法, 该方法为c 语言
static void VideoCompressonOutputCallback(void *userData, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer) {
    
    if(!sampleBuffer) return;
    CFArrayRef array = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    if(!array) return;
    CFDictionaryRef dic = (CFDictionaryRef)CFArrayGetValueAtIndex(array, 0);
    if(!dic) return;
    
    
    uint64_t timeStamp = [((__bridge_transfer NSNumber*)sourceFrameRefCon) longLongValue];
    VideoEncoder *coder = (__bridge VideoEncoder *)userData;
    if (status != noErr) return;
    
    // 判断当前帧是否为关键帧
    BOOL keyFrame = !CFDictionaryContainsKey(dic, kCMSampleAttachmentKey_NotSync);
    
    // 获取 sps pps 数据, sps pps 只需要获取一次, 保存在h.264文件开头即可
    // SPS 对于H264而言，就是编码后的第一帧，如果是读取的H264文件，就是第一个帧界定符和第二个帧界定符之间的数据的长度是4
    // PPS 就是编码后的第二帧，如果是读取的H264文件，就是第二帧界定符和第三帧界定符中间的数据长度不固定。
    if (keyFrame && !coder.sps_jf)
    {
        size_t spsSize, spsCount;
        size_t ppsSize, ppsCount;
        
        const uint8_t *spsData, *ppsData;
        
        CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
        OSStatus err0 = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesc, 0, &spsData, &spsSize, &spsCount, 0 );
        OSStatus err1 = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesc, 1, &ppsData, &ppsSize, &ppsCount, 0 );
        
        if (err0==noErr && err1==noErr)
        {
            NSData *sData = [NSData dataWithBytes:spsData length:spsSize];
            NSData *pData = [NSData dataWithBytes:ppsData length:ppsSize];
            coder.sps_jf = sData;
            coder.pps_jf = pData;
        }
    }
    
    size_t lengthAtOffset, totalLength;
    char *data;
    
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    OSStatus error = CMBlockBufferGetDataPointer(dataBuffer, 0, &lengthAtOffset, &totalLength, &data);
    
    if (error == noErr) {
        size_t offset = 0;
        const int lengthInfoSize = 4; // 返回的nalu数据前四个字节不是0001的startcode，而是大端模式的帧长度length
        
        // 循环获取nalu数据
        while (offset < totalLength - lengthInfoSize) {
            uint32_t naluLength = 0;
            memcpy(&naluLength, data + offset, lengthInfoSize); // 获取nalu的长度，
            
            // 大端模式转化为系统端模式
            naluLength = CFSwapInt32BigToHost(naluLength);
            
            RTMPVideoFrame *videoFrame = [RTMPVideoFrame new];
            videoFrame.timestamp = timeStamp;
            videoFrame.data = [[NSData alloc] initWithBytes:(data + offset + lengthInfoSize) length:naluLength];
            videoFrame.isKeyFrame = keyFrame;
            videoFrame.sps = coder.sps_jf;
            videoFrame.pps = coder.pps_jf;
            if (coder.delegate && [coder.delegate respondsToSelector:@selector(H264Encoder_call_back_audioFrame:)]) {
                [coder.delegate H264Encoder_call_back_audioFrame:videoFrame];
            }
            // 保存nalu数据到文件
            
            // 读取下一个nalu，一次回调可能包含多个nalu
            offset += lengthInfoSize + naluLength;
        }
    }
}


-(void)open{
    //创建 video encode session
    // 创建 video encode session
    // 传入视频宽高，编码类型：kCMVideoCodecType_H264
    // 编码回调：vtCompressionSessionCallback，这个回调函数为编码结果回调，编码成功后，会将数据传入此回调中。
    // (__bridge void * _Nullable)(self)：这个参数会被原封不动地传入vtCompressionSessionCallback中，此参数为编码回调同外界通信的唯一参数。
    // &_vEnSession，c语言可以给传入参数赋值。在函数内部会分配内存并初始化_vEnSession。
    _frameCount = 0;    // 帧数

    OSStatus status = VTCompressionSessionCreate(NULL, (int32_t)(self.videoConfig.pushStreamWidth), (int32_t)self.videoConfig.pushStreamHeight, kCMVideoCodecType_H264, NULL, NULL, NULL, VideoCompressonOutputCallback, (__bridge void * _Nullable)(self), &_vEnSession);
    if (status == noErr) {
        // 设置参数
        // ProfileLevel，h264的协议等级，不同的清晰度使用不同的ProfileLevel。
        VTSessionSetProperty(_vEnSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Main_AutoLevel);
        // 设置码率
        VTSessionSetProperty(_vEnSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(self.videoConfig.bitrate));
        // 设置实时编码
        VTSessionSetProperty(_vEnSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
        // 关闭重排Frame，因为有了B帧（双向预测帧，根据前后的图像计算出本帧）后，编码顺序可能跟显示顺序不同。此参数可以关闭B帧。
        VTSessionSetProperty(_vEnSession, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
        // 关键帧最大间隔，关键帧也就是I帧。此处表示关键帧最大间隔为2s。
        VTSessionSetProperty(_vEnSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)@(self.videoConfig.fps * 2));
        // 关于B帧 P帧 和I帧，请参考：http://blog.csdn.net/abcjennifer/article/details/6577934
        
        //参数设置完毕，准备开始，至此初始化完成，随时来数据，随时编码
        status = VTCompressionSessionPrepareToEncodeFrames(_vEnSession);
        if (status != noErr) {
            NSLog(@"硬编码vtsession prepare失败");
        }
    }else{
        NSLog(@"硬编码vtsession创建失败");

    }
}

-(void)close{
    
    VTCompressionSessionInvalidate(_vEnSession);
    _vEnSession = nil;
    
    self.pps_jf = nil;
    self.sps_jf = nil;
}
@end
