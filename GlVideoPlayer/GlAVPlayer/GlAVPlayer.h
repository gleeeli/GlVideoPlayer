//
//  GlAVPlayer.h
//  GlVideoPlayer
//
//  Created by 小柠檬 on 2018/12/7.
//  Copyright © 2018年 gleeeli. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "GlCommHeader.h"

#define kTransitionTime 0.2
//填充模式枚举值
typedef NS_ENUM(NSInteger,GlLayerVideoGravity){
    GlLayerVideoGravityResizeAspect,
    GlLayerVideoGravityResizeAspectFill,
    GlLayerVideoGravityResize,
};
//播放状态枚举值
typedef NS_ENUM(NSInteger,GlPlayerStatus){
    GlPlayerStatusFailed,
    GlPlayerStatusReadyToPlay,
    GlPlayerStatusUnknown,
    GlPlayerStatusBuffering,
    GlPlayerStatusPlaying,
    GlPlayerStatusStopped,
};

@interface GlAVPlayer : UIView
//AVPlayer的播放item
@property (nonatomic,strong) AVPlayerItem *item;
//总时长
@property (nonatomic,assign) CMTime totalTime;
//当前时间
@property (nonatomic,assign) CMTime currentTime;
//资产AVURLAsset
@property (nonatomic,strong) AVURLAsset *anAsset;
//播放器Playback Rate
@property (nonatomic,assign) CGFloat rate;
//播放状态
@property (nonatomic,assign,readonly) GlPlayerStatus status;
//videoGravity设置屏幕填充模式，（只写）
@property (nonatomic,assign) GlLayerVideoGravity mode;
//是否正在播放
@property (nonatomic,assign,readonly) BOOL isPlaying;
//是否全屏
@property (nonatomic,assign,readonly) BOOL isFullScreen;
//设置标题
@property (nonatomic,copy) NSString *title;
//进入后台暂停
@property (nonatomic, assign) BOOL pauseWhenAppResignActive;
//暂停因某些事件 如视图消失
@property (nonatomic, assign) BOOL pauseByEvent;
//视图是否消失
@property (nonatomic, assign) BOOL viewControllerDisappear;

//与url初始化
-(instancetype)initWithUrl:(NSURL *)url;
//将播放url放入资产中初始化播放器
-(void)assetWithURL:(NSURL *)url;
//公用同一个资产请使用此方法初始化
-(instancetype)initWithAsset:(AVURLAsset *)asset;
//播放
-(void)play;
//暂停
-(void)pause;
//停止 （移除当前视频播放下一个或者销毁视频，需调用Stop方法）
-(void)stop;

@end
