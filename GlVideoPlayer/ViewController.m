//
//  ViewController.m
//  GlVideoPlayer
//
//  Created by gleeeli on 2018/12/7.
//  Copyright © 2018年 gleeeli. All rights reserved.
//

#import "ViewController.h"
#import "GlCommHeader.h"
#import "GlAVPlayer/GlAVPlayer.h"

@interface ViewController ()
@property (nonatomic,strong) GlAVPlayer *player;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *url;
    //http://ivi.bupt.edu.cn/hls/cctv1hd.m3u8 直播网址
    url = @"http://masterpiece.lemonread.com/木偶奇遇记_导读1542941800793.mp4";
//    url = @"http://download.3g.joy.cn/video/236/60236937/1451280942752_hd.mp4";
    
    NSString *urlStr = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    //初始化播放器
    self.player = [[GlAVPlayer alloc]initWithUrl:[NSURL URLWithString:urlStr]];
    //设置标题
    [self.player setTitle:@"这是一个标题"];
    //设置播放器背景颜色
    self.player.backgroundColor = [UIColor blackColor];
    //设置播放器填充模式 默认GlLayerVideoGravityResizeAspectFill，可以不添加此语句
    self.player.mode = GlLayerVideoGravityResizeAspectFill;
    self.player.pauseWhenAppResignActive = YES;
    self.player.pauseByEvent = YES;
    [self.view addSubview:self.player];
    //约束，也可以使用Frame
    [self.player mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view);
        make.trailing.equalTo(self.view);
        make.top.mas_equalTo(self.view.mas_top);
        make.height.mas_equalTo(@250);
    }];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.player.viewControllerDisappear = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.player.viewControllerDisappear = YES;
}

@end
