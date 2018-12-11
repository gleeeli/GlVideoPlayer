//
//  GlPlayerView.m
//  SBPlayer
//
//  Created by gleeeli on 2018/12/6.
//  Copyright © 2018年 shibiao. All rights reserved.
//

#import "GlPlayerView.h"
#import <AVFoundation/AVFoundation.h>

@implementation GlPlayerView

+(Class)layerClass{
    return [AVPlayerLayer class];
}

@end
