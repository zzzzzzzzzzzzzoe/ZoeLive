//
//  RtmpStreamConfig.h
//  ZoeLive
//
//  Created by mac on 2017/7/19.
//  Copyright © 2017年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ZoeRtmpState){
    ZoeRtmpState_Ready = 0,
    ZoeRtmpState_Pending = 1,
    ZoeRtmpState_Start = 2,
    ZoeRtmpState_Stop = 3,
    ZoeRtmpState_rror = 4
};


@interface RtmpStreamConfig : NSObject
/**
 流ID
 */
@property (nonatomic, copy) NSString *streamId;

/**
 token
 */
@property (nonatomic, copy) NSString *token;

/**
 上传地址 RTMP
 */
@property (nonatomic, copy) NSString *url;

/**
 上传 IP
 */
@property (nonatomic, copy) NSString *host;

/**
 上传端口
 */
@property (nonatomic, assign) NSInteger port;
@end
