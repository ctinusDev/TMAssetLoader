//
//  TMFileManager.h
//  Pods-TMFileManager_Example
//
//  Created by TomyChen on 2019/5/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TMFileManager : NSObject

///@brief 沙盒根路径
+ (NSString *)homeDirectory;

///@brief temporary路径
+ (NSString *)temporaryDirectory;

///@brief document路径
+ (NSString *)documentDirectory;

///@brief library路径
+ (NSString *)libraryDirectory;

///@brief library路径
+ (NSString *)cachesDirectory;

///@brief 递归创建文件路径
+ (NSError *)createDirectoryIfNeeded:(NSString *)dir;

///@brief 安全地复制文件
+ (NSError *)copyItemAtPath:(NSString *)fromPath toPath:(NSString *)toPath;

///@brief 安全地移动文件
+ (NSError *)moveItemAtPath:(NSString *)fromPath toPath:(NSString *)toPath;

///@brief 删除文件夹内的所有内容
+ (void)removeAllContentsOfDirectory:(NSString *)dir;

///@brief 获取文件的大小
+ (unsigned long long)fileSizeOfItemAtPath:(NSString *)path;
@end

NS_ASSUME_NONNULL_END
