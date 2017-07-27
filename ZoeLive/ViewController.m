//
//  ViewController.m
//  ZoeLive
//
//  Created by mac on 2017/7/18.
//  Copyright © 2017年 mac. All rights reserved.
//

#import "ViewController.h"
#import "ZoeLiveManager.h"

@interface ViewController ()<ZoeLiveStatusDelegate>
@property (nonatomic,strong)ZoeLiveManager * manager;
@property (nonatomic,strong) UIButton * swichBtn , * liveBtn;
@property (nonatomic,strong) UILabel * statuLb;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _manager = [[ZoeLiveManager alloc]initWithMainView:self.view];
    _manager.capture.delegate = self;
    _swichBtn = [[UIButton alloc]initWithFrame:CGRectMake(20, 100, 100, 25)];
    _swichBtn.layer.masksToBounds = YES;
    _swichBtn.layer.borderColor = [UIColor blackColor].CGColor;
    _swichBtn.layer.borderWidth = 1;
    [_swichBtn setTitle:@"swichCamera" forState:UIControlStateNormal];
    [_swichBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_swichBtn addTarget:self action:@selector(swichclick) forControlEvents:UIControlEventTouchUpInside];
    _swichBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [self.view addSubview:_swichBtn];
    
    _statuLb = [[UILabel alloc]initWithFrame:CGRectMake(self.view.frame.size.width - 200, 100, 180, 30)];
    _statuLb.textColor = [UIColor redColor];
    [self.view addSubview:_statuLb];
    _statuLb.text = @"未连接";
    _statuLb.textAlignment = NSTextAlignmentRight;
    
    _liveBtn = [[UIButton alloc]initWithFrame:CGRectMake(50, self.view.frame.size.height - 120, self.view.frame.size.width - 100, 30)];
    [_liveBtn setTitle:@"start" forState:UIControlStateNormal];
    [_liveBtn setTitle:@"stop" forState:UIControlStateSelected];
    _liveBtn.titleLabel.textColor = [UIColor whiteColor];
    _liveBtn.backgroundColor = [UIColor blackColor];
    [_liveBtn addTarget:self action:@selector(liveClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_liveBtn];

    // Do any additional setup after loading the view, typically from a nib.
}


- (void)swichclick{
    [_manager switchCamera];
}

- (void)liveClick{
    if (_liveBtn.selected == NO) {
        [_manager startLiveWithURL:@"rtmp://60.174.36.89:1935/live/aaa"];
    }else{
        [_manager stopLive];
    }
    _liveBtn.selected = !_liveBtn.selected;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -- JFRtmpSocketDelegate
- (void)rtmpStatus:(ZoeRtmpState)status {
    switch (status) {
        case ZoeRtmpState_Ready:
            NSLog(@"准备");
            self.statuLb.text = @"准备";

            break;
        case ZoeRtmpState_Pending:
            NSLog(@"链接中");
            self.statuLb.text = @"链接中";

            break;
        case ZoeRtmpState_Start:
            NSLog(@"已连接");
            self.statuLb.text = @"已连接";
            break;
        case ZoeRtmpState_Stop:
            NSLog(@"已断开");
            self.statuLb.text = @"已断开";

            break;
        case ZoeRtmpState_rror:
            NSLog(@"链接出错");
            self.statuLb.text = @"链接出错";

            break;
        default:
            break;
    }
}
@end
