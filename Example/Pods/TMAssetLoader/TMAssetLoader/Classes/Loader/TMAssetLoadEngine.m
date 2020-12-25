//
//  TMAssetLoadEngine.m
//  SHOCK
//
//  Created by tomychen on 2019/7/26.
//  Copyright © 2019 TomyChen. All rights reserved.
//

#import "TMAssetLoadEngine.h"
#import "TMAssetLoadLocalCache.h"
#import "TMAssetLoadActionQueue.h"
#import "TMAssetLoadAction.h"
#import <CoreServices/CoreServices.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "NSObject+TM_DataBind.h"

@interface TMAssetLoadEngine ()

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, strong) TMAssetLoadActionQueue *actionQueue;

@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, strong) TMAssetLoadLocalCache *cache;

@property (nonatomic, strong) NSURL *handleUrl;

@property (nonatomic, assign) unsigned long long totalLength;

@end

@implementation TMAssetLoadEngine

NSURL* kLoadEngineURL(NSURL *url) {
    if (![url isKindOfClass:[NSURL class]]) {
        return nil;
    }
    
    if ([url isFileURL]) {
        return url;
    }
    
    NSURLComponents *components = [[NSURLComponents alloc]initWithURL:url resolvingAgainstBaseURL:NO];
    components.scheme = [components.scheme stringByAppendingString:kCustomVideoScheme];
    return components.URL;
};

NSURL* kLoadEngineOriginURL(NSURL *url) {
    if (![url isKindOfClass:[NSURL class]]) {
        return nil;
    }
    
    if ([url isFileURL]) {
        return url;
    }
    
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    components.scheme = [components.scheme stringByReplacingOccurrencesOfString:kCustomVideoScheme withString:@""];
    return components.URL;
};

#pragma mark - LifeCycle
+ (instancetype)loadEngineWithURL:(NSURL *)url {
    TMAssetLoadEngine *loadEngine = [[TMAssetLoadEngine alloc] initWithURL:url];
    return loadEngine;
}

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        _url = url;
        _handleUrl = kLoadEngineURL(url);
        
        NSString *queueKey = [NSString stringWithFormat:@"com.loadEngine.queue.%@", [NSUUID UUID].UUIDString];
        _queue = dispatch_queue_create([queueKey cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_SERIAL);
        
        _actionQueue = [[TMAssetLoadActionQueue alloc] init];
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self.actionQueue delegateQueue:nil];
        self.priority = NSURLSessionTaskPriorityDefault;
        
        _cache = [TMAssetLoadLocalCache assetLoadLocalCacheWithURL:url];
    }
    return self;
}

- (void)dealloc {
    [self.actionQueue cancelAllAction];
    [self.session finishTasksAndInvalidate];
    self.session = nil;
    NSLog(@"%s", __func__);
}

#pragma mark - Public
- (AVPlayerItem *)playerItem {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:self.handleUrl options:nil];
    if (![self.handleUrl isFileURL]) {
        [asset.resourceLoader setDelegate:self queue:self.queue];
    }
    
    return [AVPlayerItem playerItemWithAsset:asset];
}

- (void)cleanCache {
    [self.cache clearCache];
}

#pragma mark - Private
- (BOOL) handleCustomKeyRequest:(AVAssetResourceLoadingRequest*)loadingRequest
{
    NSLog(@"*** start loadingRequest:%@", loadingRequest.request);
    if (loadingRequest.isCancelled) {
        if (!loadingRequest.isFinished) {
            [loadingRequest finishLoadingWithError:[NSError errorWithDomain:@"customError" code:NSURLErrorCancelled userInfo:@{NSLocalizedFailureReasonErrorKey:(@"Resource loader cancelled"), @"ext":[NSString stringWithFormat:@"[%@:%d]", [[[NSString stringWithUTF8String:__FILE__] pathComponents] lastObject], __LINE__]}]];
        }
        return YES;
    }
    
    loadingRequest.redirect = [[self requestWithLoadingRequest:loadingRequest] mutableCopy];
    
    NSRange range = NSMakeRange(loadingRequest.dataRequest.requestedOffset, loadingRequest.dataRequest.requestedLength);
    NSLog(@"*** loading Range:%@", [NSValue valueWithRange:range]);
    
    __block NSError *err = nil;
    __block BOOL responsed = NO;
    NSMutableArray *actions = [NSMutableArray array];
    weakify(self);
    NSBlockOperation *doneOperation = [NSBlockOperation blockOperationWithBlock:^{
        if (err) {
            [loadingRequest finishLoadingWithError:err];
        } else {
            [loadingRequest finishLoading];
        }
    }];
    [actions addObject:doneOperation];
    
    NSArray<TMAssetRangeModel *> *rangeModels = [self.cache rangeModelsWithRange:range];
    [rangeModels enumerateObjectsUsingBlock:^(TMAssetRangeModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        TMAssetLoadAction *action = nil;
        if (obj.hasCache) {
            action = [[TMAssetLoadLocalAction alloc] init];
            action.loadingRequest = loadingRequest;
            action.location = obj.location;
            action.length = obj.length;
            action.cache = self.cache;
            
            NSLog(@"create LocalAction(location:%lld, length:%lld)", obj.location, obj.length);
        } else {
            NSMutableURLRequest *request = [[self requestWithLoadingRequest:loadingRequest] mutableCopy];
            request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
            [request setValue:@"text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3" forHTTPHeaderField:@"Accept"];
            [request setValue:@"zh-CN,zh;q=0.9,en;q=0.8,ja;q=0.7,zh-TW;q=0.6" forHTTPHeaderField:@"Accept-Language"];
            [request setValue:@"br, gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
            [request setValue:[NSString stringWithFormat:@"bytes=%lld-%lld", (unsigned long long)obj.location, (unsigned long long)obj.location + (unsigned long long)obj.length - 1] forHTTPHeaderField:@"Range"];
            
            action = [[TMAssetLoadNetAction alloc] init];
            action.loadingRequest = loadingRequest;
            action.request = request;
            action.location = obj.location;
            action.length = obj.length;
            [(TMAssetLoadNetAction *)action setPriority:self.priority];
            [(TMAssetLoadNetAction *)action setSession:self.session];
            action.cache = self.cache;
            
            NSLog(@"create NetAction(location:%lld, length:%lld)", obj.location, obj.length);
        }
        action.responseHandle = ^(TMAssetLoadAction *action, NSHTTPURLResponse *response, unsigned long long totalLength, NSError *error) {
            strongify(self);
            if (responsed) {
                return ;
            }
            responsed = YES;
            
            if (error) {
                err = error;
                return ;
            }

            if (response.statusCode != 206) {
                err = [NSError errorWithDomain:@"customError" code:response.statusCode userInfo:@{NSLocalizedFailureReasonErrorKey:[NSHTTPURLResponse localizedStringForStatusCode:response.statusCode], @"ext":[NSString stringWithFormat:@"[%@:%d]", [[[NSString stringWithUTF8String:__FILE__] pathComponents] lastObject], __LINE__]}];
                return;
            }
            
            self.totalLength = totalLength;
            
            NSMutableDictionary *allHeaderFileds = [response.allHeaderFields mutableCopy];
            allHeaderFileds[@"Content-Length"] = [NSString stringWithFormat:@"%lu", (unsigned long)range.length];
            allHeaderFileds[@"Content-Range"] = [NSString stringWithFormat:@"bytes %lu-%lu/%lld", (unsigned long)range.location, (unsigned long)range.location + (unsigned long)range.length -1, totalLength];
            
            NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] initWithURL:response.URL statusCode:response.statusCode HTTPVersion:@"HTTP/1.1" headerFields:allHeaderFileds];
            loadingRequest.response = httpResponse;
            NSString *contentType = (__bridge NSString * _Nullable)(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(response.MIMEType ?: @"video/mp4"), NULL));
            loadingRequest.contentInformationRequest.contentType = contentType;
            loadingRequest.contentInformationRequest.contentLength = totalLength;
            loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
            
            NSLog(@"*** response status:%zd range:%@", response.statusCode, allHeaderFileds[@"Content-Range"]);
        };
        
        action.receiveDataHandle = ^(TMAssetLoadAction *action, NSData *data) {
            if (action.isCancelled) {
                return ;
            }
            if (!err) {
                [loadingRequest.dataRequest respondWithData:data];
            }
        };
        
        action.finishHandle = ^(TMAssetLoadAction *action, NSError *error) {
            strongify(self);
            if (err || error) {
                if (error) {
                    err = error;
                }
                [loadingRequest finishLoadingWithError:err];
                [self.actionQueue.queue cancelAllOperations];
            }
        };
        
        [doneOperation addDependency:action];
        [actions addObject:action];
    }];
    
    [self.actionQueue.queue addOperations:actions waitUntilFinished:NO];
    
    return YES;
}

#pragma mark - AVAssetResourceLoaderDelegate
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSString *scheme = [[[loadingRequest request] URL] scheme];
    
    if ([scheme hasSuffix:kCustomVideoScheme]) {
        [self handleCustomKeyRequest:loadingRequest];
        return YES;
    }
    
    return NO;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    //如果用户在下载的过程中调用者取消了获取视频,则从缓存中取消这个请求
    [self.actionQueue cancelAllAction];
}

#pragma mark - Getter
- (NSURLRequest *)requestWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest{
    NSMutableURLRequest *request = [loadingRequest.request mutableCopy];
    if (request.URL) {
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:request.URL resolvingAgainstBaseURL:NO];
        components.scheme = [components.scheme stringByReplacingOccurrencesOfString:kCustomVideoScheme withString:@""];
        request.URL = components.URL;
    }

    return request;
}

- (TMAssetLoadNetAction *)netActionWithTask:(NSURLSessionTask *)task {
    __block TMAssetLoadNetAction *action = nil;
    [self.actionQueue.queue.operations  enumerateObjectsUsingBlock:^(__kindof NSOperation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[TMAssetLoadNetAction class]] && [obj task] == task) {
            action = obj;
        }
    }];
    return action;
}

#pragma mark - Setter
- (void)setPriority:(float)priority {
    _priority = priority;
    
    [self.actionQueue.queue.operations enumerateObjectsUsingBlock:^(__kindof NSOperation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[TMAssetLoadNetAction class]]) {
            TMAssetLoadNetAction *action = obj;
            action.priority = priority;
        }
    }];
}

@end
