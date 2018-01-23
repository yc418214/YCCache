//
//  YCDiskCache.m
//  YCCache
//
//  Created by 陈煜钏 on 2018/1/22.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import "YCDiskCache.h"

#import <UIKit/UIKit.h>

//macro
#import "YCCacheMacro.h"
//file
#import "YCDiskFileCache.h"
//dataBase
#import "YCDiskDataBaseCache.h"
//category
#import "NSDate+YCAddition.h"

static NSUInteger const kProperDataCostThreshold = 20 * 1024;

@interface YCDiskCache ()

@property (copy, nonatomic) NSString *cacheDirectoryPath;

@property (assign, nonatomic) YCDiskCacheStorePolicy storePolicy;

//数据大小的阀值，小于则存放于数据库，大于则写入文件
// blog: https://blog.ibireme.com/2015/10/26/yycache/
@property (assign, nonatomic) NSUInteger dataCostThreshold;

@property (strong, nonatomic) YCDiskFileCache *fileCache;

@property (strong, nonatomic) YCDiskDataBaseCache *dataBaseCache;

@end

@implementation YCDiskCache

+ (instancetype)cacheWithName:(NSString *)cacheName storePolicy:(YCDiskCacheStorePolicy)storePolicy {
    return [[YCDiskCache alloc] initWithCacheName:cacheName storePolicy:storePolicy];
}

- (instancetype)initWithCacheName:(NSString *)cacheName storePolicy:(YCDiskCacheStorePolicy)storePolicy {
    self = [super init];
    if (!self) {
        return nil;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    _cacheDirectoryPath = [documentPath stringByAppendingPathComponent:cacheName];
    BOOL isDirectory;
    BOOL fileExists = [fileManager fileExistsAtPath:_cacheDirectoryPath isDirectory:&isDirectory];
    if (!fileExists || (fileExists && !isDirectory)) {
        if (![fileManager createDirectoryAtPath:_cacheDirectoryPath withIntermediateDirectories:YES attributes:nil error:NULL]) {
            return nil;
        }
    }
    _storePolicy = storePolicy;
    _dataCostThreshold = kProperDataCostThreshold;
    _dataCachedTime = 60.f * 60.f * 24.f * 7;
    
    [self configNotification];
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - public methods

- (void)storeObject:(id<NSCoding>)object forKey:(NSString *)key {
    if (IS_EMPTY_STRING(key)) {
        return;
    }
    if (![(id)object conformsToProtocol:@protocol(NSCoding)]) {
        return;
    }
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
    if (!data) {
        return;
    }
    [self storeData:data forKey:key];
}

- (void)storeData:(NSData *)data forKey:(NSString *)key {
    if (IS_EMPTY_STRING(key)) {
        return;
    }
    if (!data || data.length == 0) {
        return;
    }
    if (self.storePolicy == YCDiskCacheStorePolicyFile ||
        data.length >= self.dataCostThreshold) {
        [self.fileCache storeData:data forKey:key];
        return;
    }
    [self.dataBaseCache storeData:data forKey:key];
}

- (id)dataForKey:(NSString *)key {
    if (IS_EMPTY_STRING(key)) {
        return nil;
    }
    if (self.storePolicy == YCDiskCacheStorePolicyFile) {
        return [self.fileCache dataForKey:key];
    }
    if (self.storePolicy == YCDiskCacheStorePolicyDataBase) {
        return [self.dataBaseCache dataForKey:key];
    }
    NSData *data = [self.dataBaseCache dataForKey:key];
    return data ? : [self.fileCache dataForKey:key];
}

- (id<NSCoding>)objectForKey:(NSString *)key {
    if (IS_EMPTY_STRING(key)) {
        return nil;
    }
    NSData *data = [self dataForKey:key];
    if (!data || data.length == 0) {
        return nil;
    }
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

- (void)cleanAllData {
    if (self.storePolicy == YCDiskCacheStorePolicyFile) {
        [self.fileCache cleanAllData];
        return;
    }
    if (self.storePolicy == YCDiskCacheStorePolicyDataBase) {
        [self.dataBaseCache cleanAllData];
        return;
    }
    [self.fileCache cleanAllData];
    [self.dataBaseCache cleanAllData];
}

#pragma mark - private methods

- (void)configNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)appDidEnterBackground {
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:backgroundTaskIdentifier];
        backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSDate *dataExpiredDate = [[NSDate yc_today] dateByAddingTimeInterval:-self.dataCachedTime];
        NSTimeInterval dataExpiredTimestamp = [dataExpiredDate timeIntervalSince1970];
        
        [self.fileCache cleanDataBeforeTimestamp:dataExpiredTimestamp];
        [self.dataBaseCache cleanDataBeforeTimestamp:dataExpiredTimestamp];
        
        [application endBackgroundTask:backgroundTaskIdentifier];
        backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    });
}

#pragma mark - getter

- (YCDiskFileCache *)fileCache {
    if (_fileCache) {
        return _fileCache;
    }
    NSString *fileCachePath = [self.cacheDirectoryPath stringByAppendingPathComponent:@"FileCache"];
    _fileCache = [YCDiskFileCache fileCacheWithPath:fileCachePath];
    return _fileCache;
}

- (YCDiskDataBaseCache *)dataBaseCache {
    if (_dataBaseCache) {
        return _dataBaseCache;
    }
    NSString *dataBaseCachePath = [self.cacheDirectoryPath stringByAppendingPathComponent:@"DataBaseCache"];
    _dataBaseCache = [YCDiskDataBaseCache dataBaseCacheWithPath:dataBaseCachePath];
    return _dataBaseCache;
}

@end
