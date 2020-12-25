//
//  TMViewController.m
//  TMAssetLoader
//
//  Created by ctinusDEV on 12/25/2020.
//  Copyright (c) 2020 ctinusDEV. All rights reserved.
//

#import "TMViewController.h"
#import <AVKit/AVKit.h>
#import <TMAssetLoader/TMAssetLoader.h>

@interface TMViewController ()
@property (nonatomic, strong) TMAssetLoadEngine *loadEngine;
@end

@implementation TMViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.loadEngine = [TMAssetLoadEngine loadEngineWithURL:[NSURL URLWithString:@"https://mvvideo5.meitudata.com/56ea0e90d6cb2653.mp4"]];
    AVPlayer *avplayer = [AVPlayer playerWithPlayerItem:[self.loadEngine playerItem]];
    [avplayer playImmediatelyAtRate:1.0];
    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:avplayer];
    layer.frame = self.view.bounds;
    [self.view.layer addSublayer:layer];
}
@end
