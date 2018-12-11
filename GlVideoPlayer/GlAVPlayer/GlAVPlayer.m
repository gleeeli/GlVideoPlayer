//
//  GlAVPlayer.m
//  GlVideoPlayer
//
//  Created by 小柠檬 on 2018/12/7.
//  Copyright © 2018年 gleeeli. All rights reserved.
//

#import "GlAVPlayer.h"
#import "GlPlayerView.h"
#import "GlControlView.h"

typedef enum : NSUInteger {
    GlCShowStatusShowAll = 0,
    GlCShowStatusHiddenAll,
    GlCShowStatusShowCenterPPBtn,//只显示中间的按钮
} GlCShowStatus;

@interface GlAVPlayer()<GlControlViewDelegate,UIGestureRecognizerDelegate>{
    id playbackTimerObserver;
}
//当前播放url
@property (nonatomic,strong) NSURL *url;
//底部控制视图
@property (nonatomic,strong) GlControlView *controlView;
//添加标题
@property (nonatomic,strong) UILabel *titleLabel;
//加载动画
@property (nonatomic,strong) UIActivityIndicatorView *activityIndeView;
//暂停和播放
@property (nonatomic, strong) UIButton *playOrPauseBtn;

@property (nonatomic, strong) GlPlayerView *backView;
@property (nonatomic, assign) GlCShowStatus cShowStatus;
@property (nonatomic, assign) BOOL isAnimationing;
//当前子视图是否隐藏
@property (nonatomic, assign) BOOL curSubIsHidden;
//自动暂停的 需要自动播放
@property (nonatomic, assign) BOOL pNeedAutoPlay;
@end

//统计从上一次归零后经过5秒就隐藏其它控件
static NSInteger playingSecond = 0;

@implementation GlAVPlayer


- (UIView *)backView {
    if (_backView == nil) {
        _backView = [[GlPlayerView alloc] init];
    }
    
    return _backView;
}
//MARK: Get方法和Set方法
-(AVPlayer *)player{
    return self.playerLayer.player;
}
-(void)setPlayer:(AVPlayer *)player{
    self.playerLayer.player = player;
}
-(AVPlayerLayer *)playerLayer{
    return (AVPlayerLayer *)self.backView.layer;
}
-(CGFloat)rate{
    return self.player.rate;
}
-(void)setRate:(CGFloat)rate{
    self.player.rate = rate;
}
-(void)setMode:(GlLayerVideoGravity)mode{
    switch (mode) {
        case GlLayerVideoGravityResizeAspect:
            self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
            break;
        case GlLayerVideoGravityResizeAspectFill:
            self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            break;
        case GlLayerVideoGravityResize:
            self.playerLayer.videoGravity = AVLayerVideoGravityResize;
            break;
    }
}
-(void)setTitle:(NSString *)title{
    self.titleLabel.text = title;
}
-(NSString *)title{
    return self.titleLabel.text;
}
//MARK:实例化
-(instancetype)initWithUrl:(NSURL *)url{
    self = [super init];
    if (self) {
        _url = url;
        [self setupPlayerUI];
        [self assetWithURL:url];
    }
    return self;
}
-(void)assetWithURL:(NSURL *)url{
    NSDictionary *options = @{ AVURLAssetPreferPreciseDurationAndTimingKey : @YES };
    self.anAsset = [[AVURLAsset alloc]initWithURL:url options:options];
    NSArray *keys = @[@"duration"];
    
    [self.anAsset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        NSError *error = nil;
        AVKeyValueStatus tracksStatus = [self.anAsset statusOfValueForKey:@"duration" error:&error];
        switch (tracksStatus) {
            case AVKeyValueStatusLoaded:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!CMTIME_IS_INDEFINITE(self.anAsset.duration)) {
                        CGFloat second = self.anAsset.duration.value / self.anAsset.duration.timescale;
                        self.controlView.totalTime = [self convertTime:second];
                        self.controlView.minValue = 0;
                        self.controlView.maxValue = second;
                    }
                });
            }
                break;
            case AVKeyValueStatusFailed:
            {
                //NSLog(@"AVKeyValueStatusFailed失败,请检查网络,或查看plist中是否添加App Transport Security Settings");
            }
                break;
            case AVKeyValueStatusCancelled:
            {
                NSLog(@"AVKeyValueStatusCancelled取消");
            }
                break;
            case AVKeyValueStatusUnknown:
            {
                NSLog(@"AVKeyValueStatusUnknown未知");
            }
                break;
            case AVKeyValueStatusLoading:
            {
                NSLog(@"AVKeyValueStatusLoading正在加载");
            }
                break;
        }
    }];
    [self setupPlayerWithAsset:self.anAsset];
    
}
-(instancetype)initWithAsset:(AVURLAsset *)asset{
    self = [super init];
    if (self) {
        [self setupPlayerUI];
        [self setupPlayerWithAsset:asset];
    }
    return self;
}
-(void)setupPlayerWithAsset:(AVURLAsset *)asset{
    self.item = [[AVPlayerItem alloc]initWithAsset:asset];
    self.player = [[AVPlayer alloc]initWithPlayerItem:self.item];
    [self.playerLayer displayIfNeeded];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self addPeriodicTimeObserver];
    //添加KVO
    [self addKVO];
    //添加消息中心
    [self addNotificationCenter];
}
//FIXME: Tracking time,跟踪时间的改变
-(void)addPeriodicTimeObserver{
    __weak typeof(self) weakSelf = self;
    playbackTimerObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.f, 1.f) queue:NULL usingBlock:^(CMTime time) {
        weakSelf.controlView.value = weakSelf.item.currentTime.value/weakSelf.item.currentTime.timescale;
        if (!CMTIME_IS_INDEFINITE(self.anAsset.duration)) {
            weakSelf.controlView.currentTime = [weakSelf convertTime:weakSelf.controlView.value];
        }
        if (playingSecond >= 5) {
            weakSelf.cShowStatus = GlCShowStatusHiddenAll;
        }
        playingSecond += 1;
    }];
}
//TODO: KVO
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus itemStatus = [[change objectForKey:NSKeyValueChangeNewKey]integerValue];
        
        switch (itemStatus) {
            case AVPlayerItemStatusUnknown:
            {
                _status = GlPlayerStatusUnknown;
                NSLog(@"AVPlayerItemStatusUnknown");
            }
                break;
            case AVPlayerItemStatusReadyToPlay:
            {
                _status = GlPlayerStatusReadyToPlay;
                NSLog(@"AVPlayerItemStatusReadyToPlay");
            }
                break;
            case AVPlayerItemStatusFailed:
            {
                _status = GlPlayerStatusFailed;
                NSLog(@"AVPlayerItemStatusFailed");
            }
                break;
            default:
                break;
        }
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {  //监听播放器的下载进度
        NSArray *loadedTimeRanges = [self.item loadedTimeRanges];
        CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval timeInterval = startSeconds + durationSeconds;// 计算缓冲总进度
        CMTime duration = self.item.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        //缓存值
        self.controlView.bufferValue=timeInterval / totalDuration;
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) { //监听播放器在缓冲数据的状态
        _status = GlPlayerStatusBuffering;
        if (!self.activityIndeView.isAnimating) {
            [self.activityIndeView startAnimating];
            self.cShowStatus = GlCShowStatusHiddenAll;
        }
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        NSLog(@"缓冲达到可播放");
        [self.activityIndeView stopAnimating];
        if (!_isPlaying) {//
            self.cShowStatus = GlCShowStatusShowCenterPPBtn;
        }
    } else if ([keyPath isEqualToString:@"rate"]){//当rate==0时为暂停,rate==1时为播放,当rate等于负数时为回放
        if ([[change objectForKey:NSKeyValueChangeNewKey]integerValue]==0) {
            _isPlaying=false;
            _status = GlPlayerStatusPlaying;
        }else{
            _isPlaying=true;
            _status = GlPlayerStatusStopped;
        }
    }
    
}
//添加KVO
-(void)addKVO{
    //监听状态属性
    [self.item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监听网络加载情况属性
    [self.item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //监听播放的区域缓存是否为空
    [self.item addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    //缓存可以播放的时候调用
    [self.item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    //监听暂停或者播放中
    [self.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
}
//MARK:添加消息中心
-(void)addNotificationCenter{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(GlPlayerItemDidPlayToEndTimeNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(willResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBecomeActiveNotification)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

//MARK: NotificationCenter
//播放结束
-(void)GlPlayerItemDidPlayToEndTimeNotification:(NSNotification *)notification{
    [self.item seekToTime:kCMTimeZero];
    self.cShowStatus = GlCShowStatusShowCenterPPBtn;
    playingSecond = 0;
    [self pause];
    
    [self.playOrPauseBtn setSelected:NO];
    
}
-(void)deviceOrientationDidChange:(NSNotification *)notification{
    UIInterfaceOrientation _interfaceOrientation=[[UIApplication sharedApplication]statusBarOrientation];
    switch (_interfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
        {
            _isFullScreen = YES;
            [self.controlView updateConstraintsIfNeeded];
            
            //删除UIView animate可以去除横竖屏切换过渡动画
            [UIView animateWithDuration:kTransitionTime delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0. options:UIViewAnimationOptionTransitionCurlUp animations:^{
                [[UIApplication sharedApplication].keyWindow addSubview:self.backView];
                [self.backView mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.edges.mas_equalTo([UIApplication sharedApplication].keyWindow);
                }];
                [self.backView layoutIfNeeded];
            } completion:nil];
        }
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
        case UIInterfaceOrientationPortrait:
        {
            _isFullScreen = NO;
            [self addSubview:self.backView];
            
            //删除UIView animate可以去除横竖屏切换过渡动画
            [UIView animateKeyframesWithDuration:kTransitionTime delay:0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^{
                [self.backView mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.edges.insets(UIEdgeInsetsZero);
                }];
                [self layoutIfNeeded];
            } completion:nil];
        }
            break;
        case UIInterfaceOrientationUnknown:
            NSLog(@"UIInterfaceOrientationUnknown");
            break;
    }
    [self layoutIfNeeded];
    
}

-(void)willResignActive:(NSNotification *)notification{
    if (_isPlaying && self.pauseWhenAppResignActive) {
        self.pNeedAutoPlay = YES;
        self.cShowStatus = GlCShowStatusShowCenterPPBtn;
        playingSecond = 0;
        [self changeStatusWithSelected:NO];
    }
}

- (void)didBecomeActiveNotification {
    if (self.pNeedAutoPlay && !self.viewControllerDisappear) {
        self.pNeedAutoPlay = NO;
        [self changeStatusWithSelected:YES];
        self.cShowStatus = GlCShowStatusShowAll;
    }
}

- (void)setViewControllerDisappear:(BOOL)viewControllerDisappear {
    _viewControllerDisappear = viewControllerDisappear;
    if (viewControllerDisappear) {//视图消失
        if (self.pauseByEvent) {
            self.pNeedAutoPlay = YES;
            [self changeStatusWithSelected:NO];
        }
    }else {//视图出现
        if (self.pNeedAutoPlay) {
            [self changeStatusWithSelected:YES];
        }
        self.pNeedAutoPlay = NO;
    }
}

//获取当前屏幕显示的viewcontroller
- (UIViewController *)getCurrentVC
{
    UIViewController *result = nil;
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows)
        {
            if (tmpWin.windowLevel == UIWindowLevelNormal)
            {
                window = tmpWin;
                break;
            }
        }
    }
    UIView *frontView = [[window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]])
        result = nextResponder;
    else
        result = window.rootViewController;
    return result;
}

//MARK: 设置界面 在此方法下面可以添加自定义视图，和删除视图
-(void)setupPlayerUI{
    //防止约束报错
    if (self.frame.size.width == 0) {
        CGRect rect = self.frame;
        rect.size.width = kScreenWidth;
        self.frame = rect;
    }
    
    [self.activityIndeView startAnimating];
    //增加一层视图 处理全屏问题
    [self addBackView];
    //添加标题
    [self addTitle];
    //添加点击事件
    [self addGestureEvent];
    //添加播放和暂停按钮
    [self addPauseAndPlayBtn];
    //添加控制视图
    [self addControlView];
    //添加加载视图
    [self addLoadingView];
    //初始化时间
    [self initTimeLabels];
    
    self.cShowStatus = GlCShowStatusHiddenAll;
}

- (void)addBackView {
    [self addSubview:self.backView];
    [self.backView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.insets(UIEdgeInsetsZero);
    }];
}

//初始化时间
-(void)initTimeLabels{
    self.controlView.currentTime = @"00:00";
    self.controlView.totalTime = @"00:00";
}
//添加加载视图
-(void)addLoadingView{
    [self.backView addSubview:self.activityIndeView];
    [self.activityIndeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(@40);
        make.center.mas_equalTo(self.backView);
    }];
}
//添加标题
-(void)addTitle{
    [self.backView addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.backView).offset(12);
        make.right.equalTo(self.backView).offset(-12);
        make.top.mas_equalTo(self.backView).offset(12);
    }];
}
//添加点击事件
-(void)addGestureEvent{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTapAction:)];
    tap.delegate = self;
    [self addGestureRecognizer:tap];
}

#pragma mark 点击空白
-(void)handleTapAction:(UITapGestureRecognizer *)gesture{
    if (self.cShowStatus == GlCShowStatusShowAll) {
        if (self.isPlaying) {
            self.cShowStatus = GlCShowStatusHiddenAll;
            
        }else {
            self.cShowStatus = GlCShowStatusShowCenterPPBtn;
        }
    }else {
        self.cShowStatus = GlCShowStatusShowAll;
    }
    playingSecond = 0;
}

//添加播放和暂停按钮
-(void)addPauseAndPlayBtn{
    [self.backView addSubview:self.playOrPauseBtn];
    [self.playOrPauseBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.backView);
        make.width.height.mas_equalTo(50);
    }];
}
//添加控制视图
-(void)addControlView{
    
    [self.backView addSubview:self.controlView];
    [self.controlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(self.backView);
        make.height.mas_equalTo(@44);
    }];
    [self layoutIfNeeded];
}
//懒加载ActivityIndicateView
-(UIActivityIndicatorView *)activityIndeView{
    if (!_activityIndeView) {
        _activityIndeView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityIndeView.hidesWhenStopped = YES;
    }
    return _activityIndeView;
}
//懒加载标题
-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.font = [UIFont systemFontOfSize:13];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.textColor = [UIColor colorWithWhite:0 alpha:0.8];
        _titleLabel.numberOfLines = 2;
    }
    return _titleLabel;
}

//懒加载控制视图
-(GlControlView *)controlView{
    if (!_controlView) {
        _controlView = [[GlControlView alloc]init];
        _controlView.delegate = self;
        _controlView.backgroundColor = [UIColor colorWithRed:2/255.0 green:0 blue:0 alpha:0.5];
        [_controlView.tapGesture requireGestureRecognizerToFail:self.playOrPauseBtn.gestureRecognizers.firstObject];
    }
    return _controlView;
}

- (UIButton *)playOrPauseBtn {
    if (_playOrPauseBtn == nil) {
        _playOrPauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playOrPauseBtn setImage:[UIImage imageNamed:@"gl_play_big"] forState:UIControlStateNormal];
        [_playOrPauseBtn setShowsTouchWhenHighlighted:YES];
        [_playOrPauseBtn setImage:[UIImage imageNamed:@"gl_pause_big"] forState:UIControlStateSelected];
        [_playOrPauseBtn addTarget:self action:@selector(playOrPauseBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playOrPauseBtn;
}

#pragma mark 设置显示子控件
- (void)setCShowStatus:(GlCShowStatus)cShowStatus {
    if (_cShowStatus  == cShowStatus) {
        return;
    }
    _cShowStatus = cShowStatus;
    switch (cShowStatus) {
        case GlCShowStatusShowAll:
        {
            self.playOrPauseBtn.hidden = NO;
            [self setCommSubViewsIsHide:NO isAnimation:YES];
        }
            break;
        case GlCShowStatusHiddenAll:
        {
            self.playOrPauseBtn.hidden = YES;
            [self setCommSubViewsIsHide:YES isAnimation:YES];
        }
            break;
        case GlCShowStatusShowCenterPPBtn:
        {
            [self setCommSubViewsIsHide:YES isAnimation:YES];
            self.playOrPauseBtn.hidden = NO;
        }
            break;
            
        default:
            break;
    }
}

- (void)setCommSubViewsIsHide:(BOOL)isHide isAnimation:(BOOL)isAnimation{
    
    if (isAnimation) {
        if (self.isAnimationing && self.curSubIsHidden == isHide) {
            return;
        }
        self.curSubIsHidden = isHide;
        self.isAnimationing = YES;
        [UIView animateWithDuration:0.2 animations:^{
            if (isHide) {
                [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.left.equalTo(self.backView).offset(12);
                    make.right.equalTo(self.backView).offset(-12);
                    make.bottom.mas_equalTo(self.backView);
                }];
                
                [self.controlView mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.left.right.top.mas_equalTo(self.backView);
                    make.height.mas_equalTo(@44);
                }];
            }else {//显示动画
                
                self.controlView.hidden = NO;
                self.titleLabel.hidden = NO;
                [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.left.equalTo(self.backView).offset(12);
                    make.right.equalTo(self.backView).offset(-12);
                    make.top.mas_equalTo(self.backView).offset(12);
                }];
                
                [self.controlView mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.left.right.bottom.mas_equalTo(self.backView);
                    make.height.mas_equalTo(@44);
                }];
            }
            [self.titleLabel layoutIfNeeded];
            [self.controlView layoutIfNeeded];
        } completion:^(BOOL finished) {
            self.isAnimationing = NO;
            
            self.controlView.hidden = isHide;
            self.titleLabel.hidden = isHide;
        }];
    }else {
        self.controlView.hidden = isHide;
        self.titleLabel.hidden = isHide;
    }
}

- (void)playOrPauseBtnClick:(UIButton *)btn {
    [self changeStatusWithSelected:!btn.selected];
}

- (void)changeStatusWithSelected:(BOOL)selected {
    self.playOrPauseBtn.selected = selected;
    self.controlView.playOrPauseBtn.selected = selected;
    
    playingSecond = 0;
    if (selected) {
        [self play];
    }else{
        [self pause];
    }
}

//MARK: SBControlViewDelegate
-(void)controlView:(GlControlView *)controlView pointSliderLocationWithCurrentValue:(CGFloat)value{
    playingSecond = 0;
    CMTime pointTime = CMTimeMake(value * self.item.currentTime.timescale, self.item.currentTime.timescale);
    [self.item seekToTime:pointTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}
-(void)controlView:(GlControlView *)controlView draggedPositionWithSlider:(UISlider *)slider{
    playingSecond = 0;
    CMTime pointTime = CMTimeMake(controlView.value * self.item.currentTime.timescale, self.item.currentTime.timescale);
    [self.item seekToTime:pointTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}
-(void)controlView:(GlControlView *)controlView withLargeButton:(UIButton *)button{
    playingSecond = 0;
    if (kScreenWidth<kScreenHeight) {
        [self interfaceOrientation:UIInterfaceOrientationLandscapeRight];
    }else{
        [self interfaceOrientation:UIInterfaceOrientationPortrait];
    }
}

- (void)controlView:(GlControlView *)controlView withPlayOrPauseButton:(UIButton *)button {
    [self playOrPauseBtnClick:self.playOrPauseBtn];
}

//MARK: UIGestureRecognizer
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if ([touch.view isKindOfClass:[GlControlView class]]) {
        return NO;
    }
    return YES;
}
//将数值转换成时间
- (NSString *)convertTime:(CGFloat)second{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if (second/3600 >= 1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    } else {
        [formatter setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [formatter stringFromDate:d];
    return showtimeNew;
}
//旋转方向
- (void)interfaceOrientation:(UIInterfaceOrientation)orientation
{
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector             = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val                  = orientation;
        
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
    if (orientation == UIInterfaceOrientationLandscapeRight||orientation == UIInterfaceOrientationLandscapeLeft) {
        // 设置横屏
    } else if (orientation == UIInterfaceOrientationPortrait) {
        // 设置竖屏
    }else if (orientation == UIInterfaceOrientationPortraitUpsideDown){
        //
    }
}

-(void)play{
    if (self.player) {
        [self.player play];
    }
}
-(void)pause{
    if (self.player) {
        [self.player pause];
    }
}
-(void)stop{
    [self.item removeObserver:self forKeyPath:@"status"];
    [self.player removeTimeObserver:playbackTimerObserver];
    [self.item removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.item removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.item removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [self.player removeObserver:self forKeyPath:@"rate"];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    if (self.player) {
        [self pause];
        self.anAsset = nil;
        self.item = nil;
        self.controlView.value = 0;
        self.controlView.currentTime = @"00:00";
        self.controlView.totalTime = @"00:00";
        self.player = nil;
        self.activityIndeView = nil;
        [self removeFromSuperview];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
