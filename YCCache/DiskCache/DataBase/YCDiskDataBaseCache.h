//
//  YCDiskDataBaseCache.h
//  YCCache
//
//  Created by 陈煜钏 on 2018/1/22.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YCDiskDataBaseCache : NSObject

+ (instancetype)dataBaseCacheWithPath:(NSString *)dataBaseCachePath;

- (void)storeData:(NSData *)data forKey:(NSString *)key;

- (NSData *)dataForKey:(NSString *)key;

- (void)deleteDataForKey:(NSString *)key;

- (void)cleanAllData;

- (void)cleanDataBeforeTimestamp:(NSTimeInterval)timestamp;

//完全删除数据库
- (void)reset;

@end
