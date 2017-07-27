//
//  RTMPSocket.h
//  ZoeLive
//
//  Created by mac on 2017/7/19.
//  Copyright © 2017年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RtmpStreamConfig.h"
#import "RTMPFrame.h"
@protocol RtmpSocketStatusDelegate <NSObject>

/** callback socket current status (回调当前网络情况) */
- (void)socketStatus:(ZoeRtmpState)status;

@end
@interface RTMPSocket : NSObject
@property (nonatomic, weak)  _Nullable id<RtmpSocketStatusDelegate> delegate;
// 初始化
- (nullable instancetype)initWithStream:(nullable RtmpStreamConfig *)stream;

- (void) start;
- (void) stop;
- (void) sendFrame:(nullable RTMPFrame*)frame;
@end
