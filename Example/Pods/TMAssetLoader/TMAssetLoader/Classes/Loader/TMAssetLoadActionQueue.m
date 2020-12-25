//
//  TMAssetLoadActionQueue.m
//  SHOCK
//
//  Created by tomychen on 2019/7/26.
//  Copyright © 2019 TomyChen. All rights reserved.
//

#import "TMAssetLoadActionQueue.h"
#import "TMAssetLoadAction.h"
#import "TMAssetLoadLocalCache.h"

@implementation TMAssetLoadActionQueue

- (instancetype)init {
    if (self = [super init]) {
        _queue = [[NSOperationQueue alloc] init];
        _queue.name = @"com.mediacache.queue";
        _queue.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (void)dealloc {
    NSLog(@"%s", __func__);
}

- (void)cancelAllAction {
    [self.queue.operations enumerateObjectsUsingBlock:^(__kindof NSOperation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        TMAssetLoadAction *action = (TMAssetLoadAction *)obj;
        if (!action.isFinished) {
            if ([action isKindOfClass:[TMAssetLoadAction class]]) {
                [action cancelAction];
            }
            [action cancel];
        }
    }];
    
    [self.queue cancelAllOperations];
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    [self.queue.operations enumerateObjectsUsingBlock:^(__kindof NSOperation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        TMAssetLoadNetAction *action = (TMAssetLoadNetAction *)obj;
        if ([action isKindOfClass:[TMAssetLoadNetAction class]] &&
            action.task == dataTask) {
            if (action.responseHandle) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                unsigned long long totalLength = 0;
                NSArray *array = [httpResponse.allHeaderFields[@"Content-Range"] componentsSeparatedByString:@"/"];
                if (array.count > 1) {
                    totalLength = [array.lastObject longLongValue];
                } else {
                    totalLength = httpResponse.expectedContentLength;
                }
                action.responseHandle(action, httpResponse, totalLength, nil);
            }
            *stop = YES;
        }
    }];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.queue.operations enumerateObjectsUsingBlock:^(__kindof NSOperation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        TMAssetLoadNetAction *action = (TMAssetLoadNetAction *)obj;
        if ([action isKindOfClass:[TMAssetLoadNetAction class]] &&
            action.task == dataTask) {
            [action.pendingData appendData:data];
            
            if (action.receiveDataHandle) {
                action.receiveDataHandle(action, data);
            }
            *stop = YES;
        }
    }];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    [self.queue.operations enumerateObjectsUsingBlock:^(__kindof NSOperation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        TMAssetLoadNetAction *action = (TMAssetLoadNetAction *)obj;
        if ([action isKindOfClass:[TMAssetLoadNetAction class]] &&
            action.task == task) {
            if (!error) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)task.response;
                unsigned long long totalLength = 0;
                NSArray *array = [httpResponse.allHeaderFields[@"Content-Range"] componentsSeparatedByString:@"/"];
                if (array.count > 1) {
                    totalLength = [array.lastObject longLongValue];
                } else {
                    totalLength = httpResponse.expectedContentLength;
                }
                [action.cache saveData:action.pendingData withRange:NSMakeRange(action.location, action.length) totalLength:totalLength];
            }
            [action finishWithError:error];
            *stop = YES;
        }
    }];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
//    NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
//    NSLog(@"%zd",urlResponse.statusCode);
//    NSLog(@"%@",urlResponse.allHeaderFields);
    
//    NSDictionary *dic = urlResponse.allHeaderFields;
//    NSLog(@"%@",dic[@"Location"]);
    completionHandler(request);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        if (credential) {
            disposition = NSURLSessionAuthChallengeUseCredential;
        } else {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        }
    } else {
        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}
@end
