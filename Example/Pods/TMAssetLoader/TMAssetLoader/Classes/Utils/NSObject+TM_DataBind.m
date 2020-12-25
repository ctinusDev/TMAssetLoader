//
//  NSObject+TM_DataBind.m
//  TMAssetLoadEngine
//
//  Created by tomychen on 2020/12/25.
//

#import "NSObject+TM_DataBind.h"
#import <objc/runtime.h>

@implementation NSObject (TM_DataBind)

static char kAssociatedObjectKey_TMAllBoundObjects;
- (NSMutableDictionary<id, id> *)tm_allBoundObjects {
    NSMutableDictionary<id, id> *dict = objc_getAssociatedObject(self, &kAssociatedObjectKey_TMAllBoundObjects);
    if (!dict) {
        dict = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &kAssociatedObjectKey_TMAllBoundObjects, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dict;
}

- (void)tm_bindObject:(id)object forKey:(NSString *)key {
    if (!key.length) {
        NSAssert(NO, @"");
        return;
    }
    if (object) {
        [[self tm_allBoundObjects] setObject:object forKey:key];
    } else {
        [[self tm_allBoundObjects] removeObjectForKey:key];
    }
}


- (id)tm_getBoundObjectForKey:(NSString *)key {
    if (!key.length) {
        NSAssert(NO, @"");
        return nil;
    }
    id storedObj = [[self tm_allBoundObjects] objectForKey:key];
    
    return storedObj;
}

- (void)tm_bindDouble:(double)doubleValue forKey:(NSString *)key {
    [self tm_bindObject:@(doubleValue) forKey:key];
}

- (double)tm_getBoundDoubleForKey:(NSString *)key {
    id object = [self tm_getBoundObjectForKey:key];
    if ([object isKindOfClass:[NSNumber class]]) {
        double doubleValue = [(NSNumber *)object doubleValue];
        return doubleValue;
        
    } else {
        return 0.0;
    }
}

- (void)tm_bindBOOL:(BOOL)boolValue forKey:(NSString *)key {
    [self tm_bindObject:@(boolValue) forKey:key];
}

- (BOOL)tm_getBoundBOOLForKey:(NSString *)key {
    id object = [self tm_getBoundObjectForKey:key];
    if ([object isKindOfClass:[NSNumber class]]) {
        BOOL boolValue = [(NSNumber *)object boolValue];
        return boolValue;
        
    } else {
        return NO;
    }
}

- (void)tm_bindLong:(long)longValue forKey:(NSString *)key {
    [self tm_bindObject:@(longValue) forKey:key];
}

- (long)tm_getBoundLongForKey:(NSString *)key {
    id object = [self tm_getBoundObjectForKey:key];
    if ([object isKindOfClass:[NSNumber class]]) {
        long longValue = [(NSNumber *)object longValue];
        return longValue;
        
    } else {
        return 0;
    }
}

- (void)tm_clearBindingForKey:(NSString *)key {
    [self tm_bindObject:nil forKey:key];
}

- (void)tm_clearAllBinding {
    [[self tm_allBoundObjects] removeAllObjects];
}

- (NSArray<NSString *> *)tm_allBindingKeys {
    NSArray<NSString *> *allKeys = [[self tm_allBoundObjects] allKeys];
    return allKeys;
}

- (BOOL)tm_hasBindingKey:(NSString *)key {
    return [[self tm_allBindingKeys] containsObject:key];
}

@end
