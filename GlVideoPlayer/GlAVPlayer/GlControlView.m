//
//  GlControlView.m
//  GlVideoPlayer
//
//  Created by gleeeli on 2018/12/11.
//  Copyright © 2018年 gleeeli. All rights reserved.
//

#import "GlControlView.h"
#import "GlCommHeader.h"

@interface GlControlView()
//当前时间
@property (nonatomic,strong) UILabel *timeLabel;
//总时间
@property (nonatomic,strong) UILabel *totalTimeLabel;
//进度条
@property (nonatomic,strong) UISlider *playSlider;
//缓存进度条
@property (nonatomic,strong) UISlider *bufferSlier;
@end

static NSInteger padding = 8;
@implementation GlControlView

//懒加载
-(UILabel *)timeLabel{
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc]init];
        _timeLabel.textAlignment = NSTextAlignmentRight;
        _timeLabel.font = [UIFont systemFontOfSize:12];
        _timeLabel.textColor = [UIColor whiteColor];
    }
    return _timeLabel;
}

-(UILabel *)totalTimeLabel{
    if (!_totalTimeLabel) {
        _totalTimeLabel = [[UILabel alloc]init];
        _totalTimeLabel.textAlignment = NSTextAlignmentLeft;
        _totalTimeLabel.font = [UIFont systemFontOfSize:12];
        _totalTimeLabel.textColor = [UIColor whiteColor];
    }
    return _totalTimeLabel;
}

-(UISlider *)playSlider{
    if (!_playSlider) {
        _playSlider = [[UISlider alloc]init];
        [_playSlider setThumbImage:[UIImage imageNamed:@"knob"] forState:UIControlStateNormal];
        _playSlider.continuous = YES;
        self.tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTap:)];
        [_playSlider addTarget:self action:@selector(handleSliderPosition:) forControlEvents:UIControlEventValueChanged];
        [_playSlider addGestureRecognizer:self.tapGesture];
        _playSlider.maximumTrackTintColor = [UIColor clearColor];
        _playSlider.minimumTrackTintColor = [UIColor whiteColor];
    }
    return _playSlider;
}

-(UIButton *)largeButton{
    if (!_largeButton) {
        _largeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _largeButton.contentMode = UIViewContentModeScaleToFill;
        [_largeButton setImage:[UIImage imageNamed:@"gl_full_screen"] forState:UIControlStateNormal];
        [_largeButton addTarget:self action:@selector(hanleLargeBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _largeButton;
}

-(UISlider *)bufferSlier{
    if (!_bufferSlier) {
        _bufferSlier = [[UISlider alloc]init];
        [_bufferSlier setThumbImage:[UIImage new] forState:UIControlStateNormal];
        _bufferSlier.continuous = YES;
        _bufferSlier.maximumTrackTintColor = [UIColor colorWithWhite:1 alpha:0.2];
        _bufferSlier.minimumTrackTintColor = [UIColor colorWithWhite:1 alpha:0.5];
        _bufferSlier.minimumValue = 0.f;
        _bufferSlier.maximumValue = 1.f;
        _bufferSlier.userInteractionEnabled = NO;
    }
    return _bufferSlier;
}

- (UIButton *)playOrPauseBtn {
    if (_playOrPauseBtn == nil) {
        _playOrPauseBtn = [[UIButton alloc] init];
        [_playOrPauseBtn setImage:[UIImage imageNamed:@"gl_play"] forState:UIControlStateNormal];
        [_playOrPauseBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateSelected];
        [_playOrPauseBtn addTarget:self action:@selector(hanlePlayOrPauseBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _playOrPauseBtn;
}

- (void)drawRect:(CGRect)rect {
    [self setupUI];
    
}

-(void)setupUI{
    [self addSubview:self.playOrPauseBtn];
    [self addSubview:self.timeLabel];
    [self addSubview:self.bufferSlier];
    [self addSubview:self.playSlider];
    [self addSubview:self.totalTimeLabel];
    [self addSubview:self.largeButton];
    //添加约束
    [self addConstraintsForSubviews];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

-(void)deviceOrientationDidChange{
    //添加约束
    [self addConstraintsForSubviews];
}

-(void)addConstraintsForSubviews{
    [self.playOrPauseBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self).offset(15);
        make.centerY.equalTo(self);
        make.width.height.mas_equalTo(23);
    }];
    
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.playOrPauseBtn.mas_trailing).offset(0);
        make.centerY.equalTo(self);
        make.right.mas_equalTo(self.playSlider).offset(-padding).priorityLow();
        //make.width.mas_equalTo(@50);
        //make.centerY.mas_equalTo(@[self.slider,self.totalTimeLabel,self.largeButton]);
    }];
    
    [self.timeLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    
    [self.playSlider mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.timeLabel.mas_right).offset(padding);
        make.right.mas_equalTo(self.totalTimeLabel.mas_left).offset(-padding);
        make.centerY.equalTo(self);
        //        if (kScreenWidth<kScreenHeight) {
        //            //后面的几个常数分别是各个控件的间隔和控件的宽度  添加自定义控件需在此修改参数
        //            make.width.mas_equalTo(kScreenWidth - padding - 50 - 50 - 30 - padding - padding);
        //        }
    }];
    
    [self.playSlider setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    [self.totalTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.playSlider.mas_right).offset(padding);
        make.right.mas_equalTo(self.largeButton.mas_left);
        make.centerY.equalTo(self);
        //make.bottom.mas_equalTo(self).offset(-padding);
        //make.width.mas_equalTo(@50).priorityHigh();
    }];
    
    [self.totalTimeLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    [self.largeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.right.mas_equalTo(self).offset(-padding);
        //make.bottom.right.mas_equalTo(self).offset(-padding);
        make.left.mas_equalTo(self.totalTimeLabel.mas_right);
        make.width.height.mas_equalTo(@30);
    }];
    [self.bufferSlier mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.playSlider);
    }];
    [self layoutIfNeeded];
}
- (void)hanlePlayOrPauseBtn:(UIButton *)button {
    if ([self.delegate respondsToSelector:@selector(controlView:withPlayOrPauseButton:)]) {
        [self.delegate controlView:self withPlayOrPauseButton:button];
    }
}

-(void)hanleLargeBtn:(UIButton *)button{
    if ([self.delegate respondsToSelector:@selector(controlView:withLargeButton:)]) {
        [self.delegate controlView:self withLargeButton:button];
    }
}
-(void)handleSliderPosition:(UISlider *)slider{
    if ([self.delegate respondsToSelector:@selector(controlView:draggedPositionWithSlider:)]) {
        [self.delegate controlView:self draggedPositionWithSlider:self.playSlider];
    }
}
-(void)handleTap:(UITapGestureRecognizer *)gesture{
    CGPoint point = [gesture locationInView:self.playSlider];
    CGFloat pointX = point.x;
    CGFloat sliderWidth = self.playSlider.frame.size.width;
    CGFloat currentValue = pointX/sliderWidth * self.playSlider.maximumValue;
    if ([self.delegate respondsToSelector:@selector(controlView:pointSliderLocationWithCurrentValue:)]) {
        [self.delegate controlView:self pointSliderLocationWithCurrentValue:currentValue];
    }
}

//setter 和 getter方法
-(void)setValue:(CGFloat)value{
    self.playSlider.value = value;
}
-(CGFloat)value{
    return self.playSlider.value;
}
-(void)setMinValue:(CGFloat)minValue{
    self.playSlider.minimumValue = minValue;
}
-(CGFloat)minValue{
    return self.playSlider.minimumValue;
}
-(void)setMaxValue:(CGFloat)maxValue{
    self.playSlider.maximumValue = maxValue;
}
-(CGFloat)maxValue{
    return self.playSlider.maximumValue;
}
-(void)setCurrentTime:(NSString *)currentTime{
    self.timeLabel.text = currentTime;
}
-(NSString *)currentTime{
    return self.timeLabel.text;
}
-(void)setTotalTime:(NSString *)totalTime{
    self.totalTimeLabel.text = totalTime;
}
-(NSString *)totalTime{
    return self.totalTimeLabel.text;
}
-(CGFloat)bufferValue{
    return self.bufferSlier.value;
}
-(void)setBufferValue:(CGFloat)bufferValue{
    self.bufferSlier.value = bufferValue;
}

@end
