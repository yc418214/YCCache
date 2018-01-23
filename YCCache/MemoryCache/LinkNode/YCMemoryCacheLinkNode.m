//
//  YCMemoryCacheLinkNode.m
//  YCCache
//
//  Created by 陈煜钏 on 2018/1/22.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import "YCMemoryCacheLinkNode.h"

@implementation YCMemoryCacheLinkNode

+ (instancetype)linkNodeWithKey:(NSString *)key value:(id)value memoryCost:(NSUInteger)memoryCost {
    YCMemoryCacheLinkNode *linkNode = [[YCMemoryCacheLinkNode alloc] init];
    linkNode.key = key;
    linkNode.value = value;
    linkNode.memoryCost = memoryCost;
    return linkNode;
}

@end
