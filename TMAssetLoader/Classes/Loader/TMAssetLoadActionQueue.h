//
//  TMAssetLoadActionQueue.h
//  SHOCK
//
//  Created by tomychen on 2019/7/26.
//  Copyright © 2019 TomyChen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMAssetLoadActionQueue : NSObject<NSURLSessionDataDelegate>

@property (nonatomic, strong, readonly) NSOperationQueue *queue;

- (void)cancelAllAction;

@end

