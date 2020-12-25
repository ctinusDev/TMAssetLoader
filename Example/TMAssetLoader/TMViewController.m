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
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        AVPlayerViewController *controller = [[AVPlayerViewController alloc] init];
        controller.player = avplayer;
        [self presentViewController:controller animated:YES completion:nil];
    });
}
@end
