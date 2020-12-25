//
//  TMAssetLoadLocalCache.h
//  SHOCK
//
//  Created by tomychen on 2019/7/26.
//  Copyright © 2019 TomyChen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMAssetRangeModel : NSObject<NSSecureCoding>

@property (nonatomic, assign) BOOL hasCache;
@property (nonatomic, assign, readonly) NSRange range;
@property (nonatomic, assign) unsigned long long location;
@property (nonatomic, assign) unsigned long long length;

@end


@interface TMAssetLoadLocalCache : NSObject

+ (instancetype)assetLoadLocalCacheWithURL:(NSURL *)url;

@property (nonatomic, strong, readonly) NSString *sourceFile;
@property (nonatomic, assign, readonly) unsigned long long totalLength;

- (void)saveData:(NSData *)data withRange:(NSRange )range totalLength:(unsigned long long)totalLength;
- (NSData *)dataWithRange:(NSRange )range;

+ (NSString *)cachePath;

- (void)clearCache;

+ (void)clearAllCache;

/**
 通过请求的range分割出已下载和未下载的range

 @param range 请求的range
 @return 已下载和未下载的range
 */
- (NSArray<TMAssetRangeModel *> *)rangeModelsWithRange:(NSRange)range;

@end
