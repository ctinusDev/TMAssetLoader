//
//  TMAssetLoadAction.h
//  SHOCK
//
//  Created by tomychen on 2019/7/26.
//  Copyright © 2019 TomyChen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class TMAssetLoadLocalCache;

@interface TMAssetLoadAction : NSOperation

@property (nonatomic, strong) TMAssetLoadLocalCache *cache;
@property (nonatomic, strong) AVAssetResourceLoadingRequest *loadingRequest;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, assign) unsigned long long location;
@property (nonatomic, assign) unsigned long long length;

@property (nonatomic, copy) void(^responseHandle)(TMAssetLoadAction *action, NSHTTPURLResponse *response, unsigned long long totalLength, NSError *error);
@property (nonatomic, copy) void(^receiveDataHandle)(TMAssetLoadAction *action, NSData *data);
@property (nonatomic, copy) void(^finishHandle)(TMAssetLoadAction *action, NSError *error);

- (void)cancelAction;

@end

@interface TMAssetLoadLocalAction : TMAssetLoadAction

@end

@interface TMAssetLoadNetAction : TMAssetLoadAction

@property (nonatomic, strong) NSMutableData *pendingData;
@property (nonatomic, weak) NSURLSession *session;
@property (nonatomic, assign) float priority;
@property (nonatomic, strong, readonly) NSURLSessionDataTask *task;

- (void)finishWithError:(NSError *)error;

@end
