//
//  NSString+TMMD5.m
//  TMAssetLoadEngine
//
//  Created by tomychen on 2020/12/25.
//

#import "NSString+TMMD5.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (TMMD5)

- (NSString *)tm_md5 {
    const char *cStr = [self UTF8String];
    unsigned char result[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(cStr, (CC_LONG)strlen(cStr), result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15],
            result[16], result[17], result[18], result[19]];
}

@end
