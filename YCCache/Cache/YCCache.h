//
//  YCCache.h
//  YCCache
//
//  Created by 陈煜钏 on 2018/1/22.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import <Foundation/Foundation.h>

//diskCache
#import "YCDiskCache.h"
//memoryCache
#import "YCMemoryCache.h"
//enum
#import "YCCacheEnum.h"

@interface YCCache : NSObject

@property (strong, nonatomic, readonly) YCDiskCache *diskCache;

@property (strong, nonatomic, readonly) YCMemoryCache *memoryCache;

@property (assign, nonatomic) NSUInteger dataDiskCachedTime;

+ (instancetype)defaultCache;

+ (instancetype)cacheWithName:(NSString *)cacheName;

+ (instancetype)cacheWithName:(NSString *)cacheName
         diskCacheStorePolicy:(YCDiskCacheStorePolicy)diskCacheStorePolicy;

- (instancetype)initWithCacheName:(NSString *)cacheName
             diskCacheStorePolicy:(YCDiskCacheStorePolicy)diskCacheStorePolicy;

- (void)storeObject:(id<NSCoding>)object forKey:(NSString *)key;

- (void)storeData:(NSData *)data forKey:(NSString *)key;

- (id<NSCoding>)objectForKey:(NSString *)key;

- (NSData *)dataForKey:(NSString *)key;

- (void)cleanCache;

@end
