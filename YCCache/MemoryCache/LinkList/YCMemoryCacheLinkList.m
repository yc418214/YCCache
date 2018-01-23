//
//  YCMemoryCacheLinkList.m
//  YCCache
//
//  Created by 陈煜钏 on 2018/1/22.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import "YCMemoryCacheLinkList.h"

#import "YCCacheMacro.h"

@interface YCMemoryCacheLinkList ()

@property (assign, nonatomic) CFMutableDictionaryRef linkNodeDictionaryRef;

@property (assign, nonatomic) YCMemoryCacheLinkNode *headNode;

@property (assign, nonatomic) YCMemoryCacheLinkNode *tailNode;

@property (assign, nonatomic, readwrite) NSUInteger totalMemoryCost;

@property (strong, nonatomic) dispatch_semaphore_t linkNodeDictionaryLock;

@end

@implementation YCMemoryCacheLinkList

+ (instancetype)linkList {
    YCMemoryCacheLinkList *linkList = [[YCMemoryCacheLinkList alloc] init];
    return linkList;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _linkNodeDictionaryRef = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        _linkNodeDictionaryLock = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)dealloc {
    if (_linkNodeDictionaryRef) {
        CFRelease(_linkNodeDictionaryRef);
    }
}

#pragma mark - public methods

- (void)insertLinkNodeAtHead:(YCMemoryCacheLinkNode *)linkNode {
    SEMAPHORE_LOCK(_linkNodeDictionaryLock);
    
    CFDictionarySetValue(_linkNodeDictionaryRef, (__bridge const void *)linkNode.key, (__bridge const void*)linkNode);
    
    self.totalMemoryCost += linkNode.memoryCost;
    if (!self.headNode) {
        self.headNode = self.tailNode = linkNode;
    } else {
        linkNode.nextNode = self.headNode;
        self.headNode.preNode = linkNode;
        self.headNode = linkNode;
    }
    
    SEMAPHORE_UNLOCK(_linkNodeDictionaryLock);
}

- (void)bringLinkNodeToHead:(YCMemoryCacheLinkNode *)linkNode {
    if (![self hasLinkNode:linkNode]) {
        return;
    }
    if (self.headNode == linkNode) {
        return;
    }
    if (self.tailNode == linkNode) {
        self.tailNode = linkNode.preNode;
        self.tailNode.nextNode = nil;
    } else {
        linkNode.nextNode.preNode = linkNode.preNode;
        linkNode.preNode.nextNode = linkNode.nextNode;
    }
    self.headNode.preNode = linkNode;
    linkNode.nextNode = self.headNode;
    linkNode.preNode = nil;
    self.headNode = linkNode;
}

- (void)removeLinkNode:(YCMemoryCacheLinkNode *)linkNode {
    if (![self hasLinkNode:linkNode]) {
        return;
    }
    SEMAPHORE_LOCK(_linkNodeDictionaryLock);
    
    CFDictionaryRemoveValue(_linkNodeDictionaryRef, (__bridge const void*)linkNode.key);
    self.totalMemoryCost -= linkNode.memoryCost;
    
    if (linkNode.nextNode) {
        linkNode.nextNode.preNode = linkNode.preNode;
    }
    if (linkNode.preNode) {
        linkNode.preNode.nextNode = linkNode.nextNode;
    }
    if (self.headNode == linkNode) {
        self.headNode = linkNode.nextNode;
    } else if (self.tailNode == linkNode) {
        self.tailNode = linkNode.preNode;
    }
    
    SEMAPHORE_UNLOCK(_linkNodeDictionaryLock);
}

- (YCMemoryCacheLinkNode *)removeTailLinkNode {
    if (!self.tailNode) {
        return nil;
    }
    SEMAPHORE_LOCK(_linkNodeDictionaryLock);
    
    YCMemoryCacheLinkNode *tailLinkNode = self.tailNode;
    CFDictionaryRemoveValue(_linkNodeDictionaryRef, (__bridge const void*)tailLinkNode.key);
    
    self.totalMemoryCost -= tailLinkNode.memoryCost;
    if (self.headNode == self.tailNode) {
        self.headNode = self.tailNode = nil;
        return tailLinkNode;
    }
    self.tailNode = tailLinkNode.preNode;
    self.tailNode.nextNode = nil;
    
    SEMAPHORE_UNLOCK(_linkNodeDictionaryLock);
    return tailLinkNode;
}

- (void)removeAllLinkNodes {
    SEMAPHORE_LOCK(_linkNodeDictionaryLock);
    
    CFDictionaryRemoveAllValues(_linkNodeDictionaryRef);
    
    self.totalMemoryCost = 0;
    self.headNode = self.tailNode = nil;
    
    SEMAPHORE_UNLOCK(_linkNodeDictionaryLock);
}

- (YCMemoryCacheLinkNode *)linkNodeForKey:(NSString *)key {
    YCMemoryCacheLinkNode *linkNode;
    SEMAPHORE_LOCK(_linkNodeDictionaryLock);
    linkNode = CFDictionaryGetValue(_linkNodeDictionaryRef, (__bridge const void *)key);
    SEMAPHORE_UNLOCK(_linkNodeDictionaryLock);
    
    return linkNode;
}

#pragma mark - private methods

- (BOOL)hasLinkNode:(YCMemoryCacheLinkNode *)linkNode {
    BOOL hasLinkNode;
    SEMAPHORE_LOCK(_linkNodeDictionaryLock);
    hasLinkNode = CFDictionaryContainsKey(_linkNodeDictionaryRef, (__bridge const void*)linkNode.key);
    SEMAPHORE_UNLOCK(_linkNodeDictionaryLock);
    
    return hasLinkNode;
}


@end
