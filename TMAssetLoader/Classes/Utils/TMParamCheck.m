//
//  TMParamCheck.m
//  TMAssetLoadEngine
//
//  Created by tomychen on 2020/12/25.
//

#import "TMParamCheck.h"
#import <objc/runtime.h>
@implementation TMParamCheck

BOOL paramCheckTypes(id param, Class types,...) {
    va_list params;
    va_start(params, types);
    Class arg;
    BOOL result = NO;
    if (types) {
        Class prev = types;
        if ([param isKindOfClass:prev]) {
            result = YES;
        }
        while (!result && (arg = va_arg(params, Class))) {
            if (arg && [param isKindOfClass:arg]) {
                result = YES;
                break;
            }
        }
        va_end(params);
    }
    if (!result) {
        NSLog(@"obj 数据格式错误:%@, type:%@",param, NSStringFromClass(object_getClass(param)));
    }
    return result;
}

@end
