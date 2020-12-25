//
//  TMAssetFileHandleManager.h
//  SHOCK
//
//  Created by tomychen on 2019/8/16.
//  Copyright © 2019 TomyChen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMAssetFileHandleManager : NSObject

+ (instancetype)shareInstance;

- (NSFileHandle *)fileHandleWithFilePath:(NSString *)filePath;

- (void)fileHandle:(NSFileHandle *)fileHandle doBlock:(void(^)(void))block;

@end
