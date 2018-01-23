//
//  YCMemoryCacheLinkList.h
//  YCCache
//
//  Created by 陈煜钏 on 2018/1/22.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import <Foundation/Foundation.h>

//linkNode
#import "YCMemoryCacheLinkNode.h"

@interface YCMemoryCacheLinkList : NSObject

@property (assign, nonatomic, readonly) NSUInteger totalMemoryCost;

+ (instancetype)linkList;

- (void)insertLinkNodeAtHead:(YCMemoryCacheLinkNode *)linkNode;

- (void)bringLinkNodeToHead:(YCMemoryCacheLinkNode *)linkNode;

- (void)removeLinkNode:(YCMemoryCacheLinkNode *)linkNode;

- (YCMemoryCacheLinkNode *)removeTailLinkNode;

- (void)removeAllLinkNodes;

- (YCMemoryCacheLinkNode *)linkNodeForKey:(NSString *)key;

@end
