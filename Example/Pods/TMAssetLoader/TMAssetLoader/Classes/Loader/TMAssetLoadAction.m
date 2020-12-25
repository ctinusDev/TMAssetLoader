//
//  TMAssetLoadAction.m
//  SHOCK
//
//  Created by tomychen on 2019/7/26.
//  Copyright © 2019 TomyChen. All rights reserved.
//

#import "TMAssetLoadAction.h"
#import "TMAssetLoadLocalCache.h"

@implementation TMAssetLoadAction

- (void)main {
    NSAssert(0, 0);
}

- (void)cancelAction {
    [self cancel];
}

@end

@implementation TMAssetLoadLocalAction

- (void)main {
    if (!self.isCancelled) {
        NSLog(@"*** start load range local:%@",[NSValue valueWithRange:NSMakeRange(self.location, self.length)]);
        NSData *data = [self.cache dataWithRange:NSMakeRange(self.location, self.length)];
        if (self.responseHandle) {
            if (data.length != self.length) {
                NSError *error = [NSError errorWithDomain:@"customError" code:NSURLErrorResourceUnavailable userInfo:@{NSLocalizedFailureReasonErrorKey:(@"数据错误"), @"ext":[NSString stringWithFormat:@"[%@:%d]", [[[NSString stringWithUTF8String:__FILE__] pathComponents] lastObject], __LINE__]}];
                self.responseHandle(self, nil, 0, error);
            } else {
                NSMutableDictionary *allHeadFileds = [NSMutableDictionary dictionary];
                allHeadFileds[@"Accept-Ranges"] = @"bytes";
                allHeadFileds[@"Connection"] = @"keep-alive";
                allHeadFileds[@"Content-Length"] = [NSString stringWithFormat:@"%lu", (unsigned long)data.length];
                allHeadFileds[@"Content-Range"] = [NSString stringWithFormat:@"bytes %lld-%lld/%lld", self.location, self.location + data.length -1, self.cache.totalLength];
                allHeadFileds[@"Content-Type"] = @"video/mp4";
                
                NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.loadingRequest.request.URL statusCode:206 HTTPVersion:@"HTTP/1.1" headerFields:allHeadFileds];
                self.responseHandle(self, response, self.cache.totalLength, nil);
            }
        }
        
        if (self.receiveDataHandle) {
            self.receiveDataHandle(self, data);
        }
        
        if (self.finishHandle) {
            self.finishHandle(self, nil);
        }
    }
}

- (void)cancelAction {
    [super cancelAction];
}

- (void)dealloc {
    NSLog(@"%s, location:%lld, length:%lld", __func__, self.location, self.length);
}

@end

@implementation TMAssetLoadNetAction {
    dispatch_semaphore_t semaphore;
}

- (void)main {
    if (!self.isCancelled) {
        NSLog(@"*** start load range net:%@",[NSValue valueWithRange:NSMakeRange(self.location, self.length)]);
        semaphore = dispatch_semaphore_create(0);
        
        self.pendingData = [NSMutableData data];
        
        @try {
            _task = [self.session dataTaskWithRequest:self.request];
            _task.priority = self.priority;
            [_task resume];
            if (semaphore) {
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            }
        } @catch (NSException *exception) {
            NSLog(@"%@",exception.reason);
            [self finishWithError:[NSError errorWithDomain:@"customError" code:NSURLErrorUnknown userInfo:@{NSLocalizedFailureReasonErrorKey:(@"Create task faild"), @"ext":[NSString stringWithFormat:@"[%@:%d]", [[[NSString stringWithUTF8String:__FILE__] pathComponents] lastObject], __LINE__]}]];
        } @finally {
            
        }
    }
}

- (void)finishWithError:(NSError *)error {
    if (self.finishHandle) {
        self.finishHandle(self, error);
    }
    
    if (semaphore) {
        dispatch_semaphore_signal(semaphore);
    }
}

- (void)cancelAction {
    [super cancelAction];
    
    [_task cancel];
    
    if (semaphore) {
        dispatch_semaphore_signal(semaphore);
    }
}

- (void)setPriority:(float)priority {
    _priority = priority;
    
    self.task.priority = priority;
}

- (void)dealloc {
    NSLog(@"%s, location:%lld, length:%lld", __func__, self.location, self.length);
}

@end
