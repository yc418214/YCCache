//
//  YCMemoryCache.m
//  YCCache
//
//  Created by 陈煜钏 on 2018/1/22.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import "YCMemoryCache.h"

#import <UIKit/UIKit.h>
//linkList
#import "YCMemoryCacheLinkList.h"
//linkNode
#import "YCMemoryCacheLinkNode.h"
//macro
#import "YCCacheMacro.h"
//category
#import "NSObject+YCAddition.h"

static NSUInteger const kBackgroundDefaultLiveTime = 30;

typedef void(^YCCacheCancelBlock)(BOOL cancel);

static YCCacheCancelBlock YCCacheCancelBlockWithHandler (dispatch_block_t handler) {
    if (!handler) {
        return nil;
    }
    __block BOOL isCancelled = NO;
    YCCacheCancelBlock cancelBlock = ^(BOOL cancel) {
        if (cancel) {
            isCancelled = YES;
            return;
        }
        if (isCancelled) {
            return;
        }
        handler();
    };
    return cancelBlock;
}

@interface YCMemoryCache ()

@property (strong, nonatomic) YCMemoryCacheLinkList *memoryLinkList;

@property (copy, nonatomic) dispatch_block_t releaseMemoryBlock;

@property (copy, nonatomic) YCCacheCancelBlock cancelReleasingMemoryBlock;

@end

@implementation YCMemoryCache

+ (instancetype)sharedCache {
    static YCMemoryCache *memoryCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        memoryCache = [[YCMemoryCache alloc] init];
    });
    return memoryCache;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _memoryCostLimit = [YCMemoryCache properMemoryCostLimit];
        _backgroundLiveTime = kBackgroundDefaultLiveTime;
        [self configNotification];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - public methods

- (void)storeObject:(id)object forKey:(NSString *)key {
    if (IS_EMPTY_STRING(key)) {
        return;
    }
    if (!object) {
        return;
    }
    size_t memoryCost = [object yc_memorySize];
    [self storeObject:object forKey:key memoryCost:memoryCost];
}

- (void)storeObject:(id)object forKey:(NSString *)key memoryCost:(NSUInteger)memoryCost {
    if (IS_EMPTY_STRING(key)) {
        return;
    }
    if (!object) {
        return;
    }
    YCMemoryCacheLinkNode *linkNode = [self.memoryLinkList linkNodeForKey:key];
    if (!linkNode) {
        linkNode = [YCMemoryCacheLinkNode linkNodeWithKey:key value:object memoryCost:memoryCost];
        [self.memoryLinkList insertLinkNodeAtHead:linkNode];
        return;
    }
    linkNode.value = object;
    linkNode.memoryCost = memoryCost;
    [self.memoryLinkList bringLinkNodeToHead:linkNode];
    
    [self checkIfNeedReleaseMemory];
}

- (id)objectForKey:(NSString *)key {
    if (IS_EMPTY_STRING(key)) {
        return nil;
    }
    YCMemoryCacheLinkNode *linkNode = [self.memoryLinkList linkNodeForKey:key];
    if (!linkNode) {
        return nil;
    }
    [self.memoryLinkList bringLinkNodeToHead:linkNode];
    return linkNode.value;
}

#pragma mark - private methods

+ (NSUInteger)properMemoryCostLimit {
    static NSUInteger totalCostLimit = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSProcessInfo *info = [NSProcessInfo processInfo];
        totalCostLimit = (NSUInteger)(info.physicalMemory * 0.15);
    });
    //each image pixel takes 4 bytes in memory
    return totalCostLimit / 4;
}

- (void)configNotification {
    [self addObserverByName:UIApplicationDidReceiveMemoryWarningNotification
                     action:@selector(appDidReceiveMemoryWarning)];
    [self addObserverByName:UIApplicationDidEnterBackgroundNotification
                     action:@selector(appDidEnterBackground)];
    [self addObserverByName:UIApplicationWillEnterForegroundNotification
                     action:@selector(appWillEnterForeground)];
}

- (void)addObserverByName:(NSString *)notificationName action:(SEL)action {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:action
                                                 name:notificationName
                                               object:nil];
}

- (void)checkIfNeedReleaseMemory {
    if (self.memoryLinkList.totalMemoryCost < self.memoryCostLimit) {
        return;
    }
    YCMemoryCacheLinkNode *tailLinkNode;
    do {
        tailLinkNode = [self.memoryLinkList removeTailLinkNode];
    } while (self.memoryLinkList.totalMemoryCost >= self.memoryCostLimit && tailLinkNode);
}

- (void)appDidReceiveMemoryWarning {
    [self.memoryLinkList removeAllLinkNodes];
}

- (void)appDidEnterBackground {
    __weak YCMemoryCache *weakSelf = self;
    dispatch_block_t handler = ^{
        [weakSelf.memoryLinkList removeAllLinkNodes];
    };
    self.cancelReleasingMemoryBlock = YCCacheCancelBlockWithHandler(handler);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.backgroundLiveTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        YCCacheCancelBlock cancelBlock = self.cancelReleasingMemoryBlock;
        if (!cancelBlock) {
            return;
        }
        cancelBlock(NO);
        self.cancelReleasingMemoryBlock = nil;
    });
}

- (void)appWillEnterForeground {
    if (!self.cancelReleasingMemoryBlock) {
        return;
    }
    self.cancelReleasingMemoryBlock(YES);
    self.cancelReleasingMemoryBlock = nil;
}

#pragma mark - getter

- (YCMemoryCacheLinkList *)memoryLinkList {
    if (_memoryLinkList) {
        return _memoryLinkList;
    }
    _memoryLinkList = [YCMemoryCacheLinkList linkList];
    return _memoryLinkList;
}

@end
