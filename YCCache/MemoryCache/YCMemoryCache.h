//
//  YCMemoryCache.h
//  YCCache
//
//  Created by 陈煜钏 on 2018/1/22.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YCMemoryCache : NSObject

@property (assign, nonatomic) NSUInteger memoryCostLimit;

+ (instancetype)sharedCache;

- (void)storeObject:(id)object forKey:(NSString *)key;

- (void)storeObject:(id)object forKey:(NSString *)key memoryCost:(NSUInteger)memoryCost;

- (id)objectForKey:(NSString *)key;

@end
