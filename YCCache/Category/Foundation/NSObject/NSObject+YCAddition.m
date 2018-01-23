//
//  NSObject+YCAddition.m
//  YCCache
//
//  Created by 陈煜钏 on 2018/1/23.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import "NSObject+YCAddition.h"

#import <malloc/malloc.h>

@implementation NSObject (YCAddition)

- (size_t)yc_memorySize {
    size_t memorySize = malloc_size((__bridge const void *)self);
    
    if ([self isKindOfClass:[NSArray class]] || [self isKindOfClass:[NSMutableArray class]]) {
        NSArray *array = (NSArray *)self;
        for (id object in array) {
            memorySize += malloc_size((__bridge const void *)object);
        }
        return memorySize;
    }
    if ([self isKindOfClass:[NSDictionary class]] || [self isKindOfClass:[NSMutableDictionary class]]) {
        NSArray *valuesArray = ((NSDictionary *)self).allValues;
        for (id value in valuesArray) {
            memorySize += malloc_size((__bridge const void *)value);
        }
        return memorySize;
    }
    if ([self isKindOfClass:[NSSet class]] || [self isKindOfClass:[NSMutableSet class]]) {
        NSSet *set = (NSSet *)self;
        for (id object in set) {
            memorySize += malloc_size((__bridge const void *)object);
        }
        return memorySize;
    }
    
    return memorySize;
}

@end
