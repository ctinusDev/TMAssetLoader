//
//  TMAssetLoadLocalCache.m
//  SHOCK
//
//  Created by tomychen on 2019/7/26.
//  Copyright © 2019 TomyChen. All rights reserved.
//

#import "TMAssetLoadLocalCache.h"
#import "TMAssetFileHandleManager.h"
#import "TMParamCheck.h"
#import "NSString+TMMD5.h"
#import "TMFileManager.h"
#import "NSObject+TM_DataBind.h"

@implementation TMAssetRangeModel

#pragma mark - Coding
+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        self.hasCache = [coder decodeBoolForKey:@"hasCache"];
        self.location = [coder decodeInt64ForKey:@"location"];
        self.length = [coder decodeInt64ForKey:@"length"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeBool:self.hasCache forKey:@"hasCache"];
    [coder encodeInt64:self.location forKey:@"location"];
    [coder encodeInt64:self.length forKey:@"length"];
}

#pragma mark - Copying

- (id)copyWithZone:(NSZone *)zone {
    TMAssetRangeModel *new = [[TMAssetRangeModel alloc] init];
    new.hasCache = self.hasCache;
    new.location = self.location;
    new.length = self.length;
    return new;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    TMAssetRangeModel *new = [[TMAssetRangeModel alloc] init];
    new.hasCache = self.hasCache;
    new.location = self.location;
    new.length = self.length;
    return new;
}

#pragma mark - Getter
- (NSRange)range {
    return NSMakeRange(self.location, self.length);
}


#pragma mark - Setter

@end

@interface TMAssetLoadLocalCache ()

@property (nonatomic, strong) NSMutableArray<TMAssetRangeModel *> *rangeModels;

@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSString *sourceFile;
@property (nonatomic, strong) NSString *rangeListFile;

@property (nonatomic, strong) NSFileHandle *fileHandle;

@property (nonatomic, assign) unsigned long long fileSize;

@end

@implementation TMAssetLoadLocalCache
#pragma mark - LifeCycle
+ (instancetype)assetLoadLocalCacheWithURL:(NSURL *)url {
    kParamCheck(url, nil , NSURL);
    TMAssetLoadLocalCache *cache = [[TMAssetLoadLocalCache alloc] initWithURL:url];
    return cache;
}

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        self.fileName = [url.absoluteString tm_md5];
        self.filePath = [[TMAssetLoadLocalCache cachePath] stringByAppendingPathComponent:self.fileName];
        self.sourceFile = [self.filePath stringByAppendingPathComponent:self.fileName];
        self.rangeListFile = [self.filePath stringByAppendingPathComponent:@"rangeList"];
        [self loadCacheData];
    }
    return self;
}

- (void)dealloc {
    [self.fileHandle closeFile];
    NSLog(@"%@ %s", self, __func__);
}

- (void)loadCacheData {
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.filePath]) {
        NSError *error = [TMFileManager createDirectoryIfNeeded:self.filePath];
        if (error) {
            NSLog(@"%@", error);
            return;
        }
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.sourceFile]) {
        BOOL result = [[NSFileManager defaultManager] createFileAtPath:self.sourceFile contents:nil attributes:@{NSFileProtectionKey : NSFileProtectionCompleteUntilFirstUserAuthentication}];
        if (!result) {
            NSLog(@"create sourceFile Failed:%@", self.sourceFile);
            return;
        }
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.rangeListFile]) {
        BOOL result = [[NSFileManager defaultManager] createFileAtPath:self.rangeListFile contents:nil attributes:@{NSFileProtectionKey : NSFileProtectionCompleteUntilFirstUserAuthentication}];
        if (!result) {
            NSLog(@"create sourceFile Failed:%@", self.rangeListFile);
            return;
        }
    }
    
//    NSError *error = nil;
//    if (@available(iOS 14.0, *)) {
//        NSMutableArray *rangeModels = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchivedArrayOfObjectsOfClass:TMAssetRangeModel.class fromData:[NSData dataWithContentsOfFile:[self rangeListFile]] error:&error]];
//        if (error) {
//            NSLog(@"%@", error);
//        }
//
//        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"location" ascending:YES];
//        [rangeModels sortUsingDescriptors:@[sort]];
//        self.rangeModels = rangeModels;
//    } else {
        // Fallback on earlier versions
        NSMutableArray *rangeModels = [NSKeyedUnarchiver unarchiveObjectWithFile:[self rangeListFile]];
//    }
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"location" ascending:YES];
    [rangeModels sortUsingDescriptors:@[sort]];
    self.rangeModels = rangeModels;
    
    self.fileHandle = [[TMAssetFileHandleManager shareInstance] fileHandleWithFilePath:self.sourceFile];
    
    self.fileSize = [self totalLength];
}

- (void)checkMergeAndSaveRanges {
    NSMutableArray *mergeRanges = [NSMutableArray array];
    [self.rangeModels enumerateObjectsUsingBlock:^(TMAssetRangeModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!mergeRanges.lastObject) {
            [mergeRanges addObject:obj];
        } else {
            TMAssetRangeModel *lastRangeModel = mergeRanges.lastObject;
            TMAssetRangeModel *rangeModel = obj;
            if (NSIntersectionRange(lastRangeModel.range, rangeModel.range).location != 0 ||
                NSMaxRange(lastRangeModel.range) == rangeModel.range.location ||
                NSMaxRange(rangeModel.range) == lastRangeModel.range.location) {
                NSRange merge = NSUnionRange(lastRangeModel.range, rangeModel.range);
                lastRangeModel.location = merge.location;
                lastRangeModel.length = merge.length;
            } else {
                [mergeRanges addObject:rangeModel];
            }
        }
    }];
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"location" ascending:YES];
    [mergeRanges sortUsingDescriptors:@[sort]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.rangeListFile]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.rangeListFile error:nil];
    }
    
    if ([NSKeyedArchiver archiveRootObject:mergeRanges toFile:self.rangeListFile]) {
        NSLog(@"*** success saveRangeList");
    } else {
        NSLog(@"*** failed saveRangeList");
    }
}

#pragma mark - Public
- (NSArray<TMAssetRangeModel *> *)rangeModelsWithRange:(NSRange)range {
    NSLog(@"*** 解析下载数据");
    __block NSRange loadRange = range;
    NSMutableArray *loadModels = [NSMutableArray array];
    [self.rangeModels enumerateObjectsUsingBlock:^(TMAssetRangeModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (NSIntersectionRange(loadRange, obj.range).length != 0) {
            if (loadRange.location < obj.location) {
                if (NSMaxRange(loadRange) < NSMaxRange(obj.range)) {
                    if (obj.location - loadRange.location > 0) {
                        TMAssetRangeModel *model = [[TMAssetRangeModel alloc] init];
                        model.location = loadRange.location;
                        model.length = obj.location - loadRange.location;
                        model.hasCache = NO;
                        [loadModels addObject:model];
                    }
                    loadRange = NSMakeRange(obj.location, NSMaxRange(loadRange) - obj.location);
                    
                    if (NSMaxRange(loadRange) - obj.location > 0) {
                        TMAssetRangeModel *model1 = [[TMAssetRangeModel alloc] init];
                        model1.location = obj.location;
                        model1.length = NSMaxRange(loadRange) - obj.location;
                        model1.hasCache = YES;
                        [loadModels addObject:model1];
                    }
                    
                    loadRange = NSMakeRange(0, 0);
                } else {
                    if (obj.location - loadRange.location > 0) {
                        TMAssetRangeModel *model = [[TMAssetRangeModel alloc] init];
                        model.location = loadRange.location;
                        model.length = obj.location - loadRange.location;
                        model.hasCache = NO;
                        [loadModels addObject:model];
                    }
                    loadRange = NSMakeRange(obj.location, NSMaxRange(loadRange) - obj.location);

                    if (obj.length > 0) {
                        TMAssetRangeModel *model1 = [[TMAssetRangeModel alloc] init];
                        model1.location = obj.location;
                        model1.length = obj.length;
                        model1.hasCache = YES;
                        [loadModels addObject:model1];
                    }

                    loadRange = NSMakeRange(NSMaxRange(obj.range), NSMaxRange(range) - NSMaxRange(obj.range));
                }
            } else {
                if (NSMaxRange(loadRange) < NSMaxRange(obj.range)) {
                    if (loadRange.length > 0) {
                        TMAssetRangeModel *model = [[TMAssetRangeModel alloc] init];
                        model.location = loadRange.location;
                        model.length = loadRange.length;
                        model.hasCache = YES;
                        [loadModels addObject:model];
                    }
                    
                    loadRange = NSMakeRange(0, 0);
                } else {
                    if (NSMaxRange(obj.range) - loadRange.location > 0) {
                        TMAssetRangeModel *model = [[TMAssetRangeModel alloc] init];
                        model.location = loadRange.location;
                        model.length = NSMaxRange(obj.range) - loadRange.location;
                        model.hasCache = YES;
                        [loadModels addObject:model];
                    }
                    
                    loadRange = NSMakeRange(NSMaxRange(obj.range), NSMaxRange(range) - NSMaxRange(obj.range));
                }
            }
        }
    }];
    
    if (loadRange.length != 0) {
        TMAssetRangeModel *model = [[TMAssetRangeModel alloc] init];
        model.location = loadRange.location;
        model.length = loadRange.length;
        model.hasCache = NO;
        [loadModels addObject:model];
    }
    NSLog(@"*** 解析下载数据完成");
    return loadModels;
}

- (void)saveData:(NSData *)data withRange:(NSRange)range totalLength:(unsigned long long)totalLength {
    NSLog(@"*** start save data %@ withRange:%@", self, [NSValue valueWithRange:range]);
    
    unsigned long long fixTotalLength = MAX(NSMaxRange(range), totalLength);
    if (![self expandFileSize:fixTotalLength]) {
        return;
    }
    
    unsigned long long sourceFileSize = [TMFileManager fileSizeOfItemAtPath:self.sourceFile];
    if (range.location > sourceFileSize || NSMaxRange(range) > sourceFileSize) {
        NSLog(@"*** save data failed %@ range(%lu) ratherThan fileSize:%lld", self, (unsigned long)range.location, sourceFileSize);
        return;
    }
    
    if (data.length != range.length) {
        NSLog(@"*** save data failed %@ dateLength(%lu) notEqual rangeLength(%lu)", self, (unsigned long)data.length, (unsigned long)range.length);
        return;
    }
    
    TMAssetRangeModel *rangeModel = [[TMAssetRangeModel alloc] init];
    rangeModel.location = range.location;
    rangeModel.length = range.length;
    rangeModel.hasCache = YES;
    [self.rangeModels addObject:rangeModel];
    
    weakify(self);
    [[TMAssetFileHandleManager shareInstance] fileHandle:self.fileHandle doBlock:^{
        strongify(self);
        @try {
            [self.fileHandle seekToFileOffset:range.location];
            [self.fileHandle writeData:data];
            [self.fileHandle synchronizeFile];
        } @catch (NSException *exception) {
            NSLog(@"%@",exception.reason);
        } @finally {
            
        }

    }];

    
    [self checkMergeAndSaveRanges];
    
    sourceFileSize = [TMFileManager fileSizeOfItemAtPath:self.sourceFile];

    NSLog(@"*** save data success %@ withRange:%@ totalLength:%lld", self, [NSValue valueWithRange:range], sourceFileSize);
}

- (NSData *)dataWithRange:(NSRange)range {
    NSLog(@"*** get data withRange:%@", [NSValue valueWithRange:range]);
    if (range.location > [TMFileManager fileSizeOfItemAtPath:self.sourceFile] ||
        NSMaxRange(range) > [TMFileManager fileSizeOfItemAtPath:self.sourceFile]) {
        NSAssert(0, 0);
        return nil;
    }
    
    __block NSData *data = nil;
    weakify(self);
    [[TMAssetFileHandleManager shareInstance] fileHandle:self.fileHandle doBlock:^{
        strongify(self);
        @try {
            [self.fileHandle seekToFileOffset:range.location];
            data = [self.fileHandle readDataOfLength:range.length];
        } @catch (NSException *exception) {
            NSLog(@"%@",exception.reason);
            data = nil;
        } @finally {
            
        }
        
    }];
    NSLog(@"*** get data successed withRange:%@", [NSValue valueWithRange:range]);

    return data;
}

+ (NSString *)cachePath {
    return [[TMFileManager libraryDirectory] stringByAppendingPathComponent:@"TMAssetCaches"];
}

- (void)clearCache {
    self.rangeModels = nil;
    [[NSFileManager defaultManager] removeItemAtPath:self.rangeListFile error:nil];
}

+ (void)clearAllCache {
    [TMFileManager removeAllContentsOfDirectory:[self cachePath]];
}

#pragma mark - Private
- (BOOL)expandFileSize:(unsigned long long)fileSize {
    if (fileSize <= self.fileSize) {
        return YES;
    }
    
    NSLog(@"开始扩充缓存文件:%lld",fileSize);
    unsigned long long difference = fileSize - self.fileSize;
    self.fileSize  = fileSize;
    
    void *bytes = malloc(difference);
    memset(bytes, 1, difference);
    NSData *data = [NSData dataWithBytes:bytes length:difference];
    free(bytes);
    bytes = nil;
    
    weakify(self);
    [[TMAssetFileHandleManager shareInstance] fileHandle:self.fileHandle doBlock:^{
        strongify(self);
        @try {
            [self.fileHandle seekToEndOfFile];
            [self.fileHandle writeData:data];
            [self.fileHandle synchronizeFile];
        } @catch (NSException *exception) {
            NSLog(@"%@",exception.reason);
        } @finally {
            
        }
        NSLog(@"扩充缓存文件完成:%lld",fileSize);
    }];
    return YES;
}

#pragma mark - Getter
- (unsigned long long)totalLength {
    return [TMFileManager fileSizeOfItemAtPath:self.sourceFile];
}

#pragma mark - Setter


@end
