//
//  TMAssetFileHandleManager.m
//  SHOCK
//
//  Created by tomychen on 2019/8/16.
//  Copyright © 2019 TomyChen. All rights reserved.
//

#import "TMAssetFileHandleManager.h"
#import "TMParamCheck.h"
#import "NSString+TMMD5.h"
#import "TMBlockUtils.h"
#import "NSObject+TM_DataBind.h"

@interface TMAssetFileHandleManager ()

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, strong) NSMapTable *map;

@end

@implementation TMAssetFileHandleManager

#pragma mark - LifeCycle
+ (instancetype)shareInstance {
    TMAssetFileHandleManager *manager = [[TMAssetFileHandleManager alloc] init];
    
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        _map = [NSMapTable strongToWeakObjectsMapTable];
        
        _queue = dispatch_queue_create("com.fileHandleManager.queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - Public
- (NSFileHandle *)fileHandleWithFilePath:(NSString *)filePath {
    kParamCheck(filePath, nil, NSString);
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return nil;
    }
    
    NSFileHandle *fileHandle = [self.map objectForKey:filePath];
    if (!fileHandle) {
        NSError *error = nil;
        fileHandle = [NSFileHandle fileHandleForUpdatingURL:[NSURL fileURLWithPath:filePath] error:&error];
        if (error) {
            NSLog(@"%@" ,error);
        } else {
            [self.map setObject:fileHandle forKey:filePath];
        }
    }
    
    NSString *queueName = [NSString stringWithFormat:@"com.fileHandleManager.queue.%@", [filePath tm_md5]];
    dispatch_queue_t queue = dispatch_queue_create([queueName cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_SERIAL);
    [fileHandle tm_bindObject:queue forKey:@"FileHandleQueue"];
    
    return fileHandle;
}

- (void)fileHandle:(NSFileHandle *)fileHandle doBlock:(void (^)(void))block {
    dispatch_queue_t queue = [fileHandle tm_getBoundObjectForKey:@"FileHandleQueue"];
    if (queue) {
        doBlockSync(queue, ^{
            if (block) {
                block();
            }
        });
    }
}

#pragma mark - Setter

#pragma mark - Getter


@end
