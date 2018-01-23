//
//  YCDiskCache.h
//  YCCache
//
//  Created by 陈煜钏 on 2018/1/22.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YCCacheEnum.h"

@interface YCDiskCache : NSObject

//数据缓存的时间，超过则清理缓存
@property (assign, nonatomic) NSTimeInterval dataCachedTime;

+ (instancetype)cacheWithName:(NSString *)cacheName storePolicy:(YCDiskCacheStorePolicy)storePolicy;

- (instancetype)initWithCacheName:(NSString *)cacheName
                      storePolicy:(YCDiskCacheStorePolicy)storePolicy;

- (void)storeObject:(id<NSCoding>)object forKey:(NSString *)key;

- (void)storeData:(NSData *)data forKey:(NSString *)key;

- (id)dataForKey:(NSString *)key;

- (id<NSCoding>)objectForKey:(NSString *)key;

- (void)cleanAllData;

@end
