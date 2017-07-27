//
//  ZoeLiveManager.h
//  ZoeLive
//
//  Created by mac on 2017/7/19.
//  Copyright © 2017年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "RtmpStreamConfig.h"
#import "ZoeLiveCapture.h"



@interface ZoeLiveManager : NSObject
@property (nonatomic,weak)id<ZoeLiveStatusDelegate>delegate;
@property (nonatomic,strong) ZoeLiveCapture * capture;
- (instancetype )initWithMainView:(UIView *)view;
- (BOOL)startLiveWithURL:(NSString *)url;
- (void)stopLive;
- (void)switchCamera;
@end
