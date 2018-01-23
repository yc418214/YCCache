//
//  YCMemoryCacheLinkNode.h
//  YCCache
//
//  Created by 陈煜钏 on 2018/1/22.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YCMemoryCacheLinkNode : NSObject

@property (assign, nonatomic) YCMemoryCacheLinkNode *preNode;

@property (assign, nonatomic) YCMemoryCacheLinkNode *nextNode;

@property (assign, nonatomic) NSUInteger memoryCost;

@property (copy, nonatomic) NSString *key;

@property (strong, nonatomic) id value;

+ (instancetype)linkNodeWithKey:(NSString *)key value:(id)value memoryCost:(NSUInteger)memoryCost;

@end
