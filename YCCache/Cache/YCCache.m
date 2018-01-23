//
//  YCCache.m
//  YCCache
//
//  Created by 陈煜钏 on 2018/1/22.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import "YCCache.h"

//macro
#import "YCCacheMacro.h"

static NSString * const kDefaultCacheName = @"YCDefaultCache";

@interface YCCache ()

@property (strong, nonatomic, readwrite) YCDiskCache *diskCache;

@property (strong, nonatomic, readwrite) YCMemoryCache *memoryCache;

@end

@implementation YCCache

+ (instancetype)defaultCache {
    static YCCache *defaultCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultCache = [[YCCache alloc] initWithCacheName:kDefaultCacheName diskCacheStorePolicy:YCDiskCacheStorePolicyMix];
    });
    return defaultCache;
}

+ (instancetype)cacheWithName:(NSString *)cacheName {
    return [[self alloc] initWithCacheName:cacheName diskCacheStorePolicy:YCDiskCacheStorePolicyMix];
}

+ (instancetype)cacheWithName:(NSString *)cacheName diskCacheStorePolicy:(YCDiskCacheStorePolicy)diskCacheStorePolicy {
    return [[self alloc] initWithCacheName:cacheName diskCacheStorePolicy:diskCacheStorePolicy];
}

- (instancetype)initWithCacheName:(NSString *)cacheName diskCacheStorePolicy:(YCDiskCacheStorePolicy)diskCacheStorePolicy {
    self = [super init];
    if (self) {
        _diskCache = [YCDiskCache cacheWithName:cacheName storePolicy:diskCacheStorePolicy];
        _memoryCache = [YCMemoryCache sharedCache];
    }
    return self;
}

#pragma mark - public methods

- (void)storeObject:(id<NSCoding>)object forKey:(NSString *)key {
    if (IS_EMPTY_STRING(key)) {
        return;
    }
    [self.memoryCache storeObject:object forKey:key];
    
    if ([(id)object isKindOfClass:[NSData class]]) {
        [self.diskCache storeData:(NSData *)object forKey:key];
        return;
    }
    if (![(id)object conformsToProtocol:@protocol(NSCoding)]) {
        return;
    }
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
    if (!data || data.length == 0) {
        return;
    }
    [self.diskCache storeData:data forKey:key];
}

- (void)storeData:(NSData *)data forKey:(NSString *)key {
    if (IS_EMPTY_STRING(key)) {
        return;
    }
    if (!data || data.length == 0) {
        return;
    }
    [self.memoryCache storeObject:data forKey:key];
    [self.diskCache storeData:data forKey:key];
}

- (id<NSCoding>)objectForKey:(NSString *)key {
    id object = [self.memoryCache objectForKey:key];
    if (!object && ![(id)object conformsToProtocol:@protocol(NSCoding)]) {
        return nil;
    }
    if (!object) {
        object = [self.diskCache objectForKey:key];
        [self.memoryCache storeObject:object forKey:key];
    }
    return object;
}

- (NSData *)dataForKey:(NSString *)key {
    NSData *data = [self.memoryCache objectForKey:key];
    if (!data) {
        data = [self.diskCache dataForKey:key];
        [self.memoryCache storeObject:data forKey:key];
    }
    return data;
}

- (void)cleanCache {
    [self.diskCache cleanAllData];
}

#pragma mark - setter

- (void)setDataDiskCachedTime:(NSUInteger)dataDiskCachedTime {
    _dataDiskCachedTime = dataDiskCachedTime;
    
    self.diskCache.dataCachedTime = dataDiskCachedTime;
}\

@end
