//
//  TMFileManager.m
//  Pods-TMFileManager_Example
//
//  Created by TomyChen on 2019/5/13.
//

#import "TMFileManager.h"

@implementation TMFileManager

+ (NSString *)homeDirectory {
    return NSHomeDirectory();
}

+ (NSString *)temporaryDirectory {
    return NSTemporaryDirectory();
}

+ (NSString *)documentDirectory {
    static NSString * docPath = nil;
    if (docPath == nil)
    {
        NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        docPath = paths.count > 0 ? [paths[0] copy] : nil;
        if (docPath.length == 0)
        {
            docPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        }
    }
    return docPath;
}

+ (NSString *)libraryDirectory {
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Library"];
}

+ (NSString *)cachesDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDir = paths.firstObject;
    return cacheDir;
}


+ (NSError *)createDirectoryIfNeeded:(NSString *)dir {
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir])
    {
        NSError *error;
        if ([[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&error])
        {
            NSLog(@"[File] check and create dir: %@", dir);
        }
        else
        {
            NSLog(@"[File] check and create dir failed! dir: %@,\r error: %@", dir, (error ? : @"unknown"));
            return error;
        }
    }
    return nil;
}

+ (NSError *)copyItemAtPath:(NSString *)fromPath toPath:(NSString *)toPath {
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fromPath isEqualToString:toPath])
    {
        return nil;
    }
    
    if ((fromPath == nil) || (toPath == nil))
    {
        NSLog(@"[FileManager] copy file failed! file of fromPath or toPath is null, fromPath = %@, toPath = %@", fromPath, toPath);
        return [NSError errorWithDomain:@"file of fromPath or toPath is null" code:-1 userInfo:nil];
    }
    
    if (![fileManager fileExistsAtPath:fromPath])
    {
        NSLog(@"[FileManager] copy file failed! file of fromPath doesn't exist, fromPath = %@", fromPath);
        return error ? : [NSError errorWithDomain:@"file of fromPath doesn't exist" code:-1 userInfo:nil];
    }
    
    if ([fileManager fileExistsAtPath:toPath])
    {
        if (![fileManager removeItemAtPath:toPath error:&error])
        {
            NSLog(@"[FileManager] copy file failed! remove file of toPath failed, error = %@", error);
            return error ? : [NSError errorWithDomain:@"remove file of toPath failed" code:-1 userInfo:nil];
        }
    }
    
    if (![fileManager copyItemAtPath:fromPath toPath:toPath error:&error])
    {
        NSLog(@"[FileManager] copy file failed! error = %@", error);
        return error ? : [NSError errorWithDomain:@"copy file failed" code:-1 userInfo:nil];
    }
    
    return nil;
}

+ (NSError *)moveItemAtPath:(NSString *)fromPath toPath:(NSString *)toPath
{
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fromPath isEqualToString:toPath])
    {
        return nil;
    }
    
    if ((fromPath == nil) || (toPath == nil))
    {
        NSLog(@"[FileManager] move file failed! file of fromPath or toPath is null, fromPath = %@, toPath = %@", fromPath, toPath);
        return [NSError errorWithDomain:@"file of fromPath or toPath is null" code:-1 userInfo:nil];
    }
    
    if (![fileManager fileExistsAtPath:fromPath])
    {
        NSLog(@"[FileManager] move file failed! file of fromPath doesn't exist, fromPath = %@", fromPath);
        return [NSError errorWithDomain:@"file of fromPath doesn't exist" code:-1 userInfo:nil];
    }
    
    if ([fileManager fileExistsAtPath:toPath])
    {
        if (![fileManager removeItemAtPath:toPath error:&error])
        {
            NSLog(@"[FileManager] move file failed! remove file of toPath failed, error = %@", error);
            return error ? : [NSError errorWithDomain:@"remove file of toPath failed" code:-1 userInfo:nil];
        }
    }
    
    if (![fileManager moveItemAtPath:fromPath toPath:toPath error:&error])
    {
        NSLog(@"[FileManager] move file failed! error = %@", error);
        return error ? : [NSError errorWithDomain:@"move file failed" code:-1 userInfo:nil];
    }
    
    return nil;
}

+ (void)removeAllContentsOfDirectory:(NSString *)dir {
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *files = [fileManager contentsOfDirectoryAtPath:dir error:&error];
    if (error != nil)
    {
        NSLog(@"[FileManager] get files in dir failed! dir = %@", dir);
        return;
    }
    
    for (NSString *file in files)
    {
        NSString *path = [dir stringByAppendingPathComponent:file];
        if (![fileManager removeItemAtPath:path error:&error])
        {
            NSLog(@"[FileManager] delete file failed! path = %@", path);
        }
    }
}

+ (unsigned long long)fileSizeOfItemAtPath:(NSString *)path {
    NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    return dict ? [dict fileSize] : 0;
}

@end
