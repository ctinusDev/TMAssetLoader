//
//  TMAssetLoadEngine.h
//  SHOCK
//
//  Created by tomychen on 2019/7/26.
//  Copyright © 2019 TomyChen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define kCustomVideoScheme @"tmtp"


@interface TMAssetLoadEngine : NSObject<AVAssetResourceLoaderDelegate>

@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, strong, readonly) dispatch_queue_t queue;
@property (nonatomic, assign) float priority;

+ (instancetype)loadEngineWithURL:(NSURL *)url;
- (AVPlayerItem *)playerItem;

- (void)cleanCache;

//extern NSURL* kLoadEngineURL(NSURL *url);
//extern NSURL* kLoadEngineOriginURL(NSURL *url);

@end
