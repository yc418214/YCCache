//
//  YCDiskFileCache.m
//  YCCache
//
//  Created by 陈煜钏 on 2018/1/22.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import "YCDiskFileCache.h"

#import "YCCacheMacro.h"

@interface YCDiskFileCache ()

@property (copy, nonatomic) NSString *fileCacheDirectoryPath;

@property (strong, nonatomic) NSFileManager *fileManager;

@property (strong, nonatomic) dispatch_queue_t fileCacheOperaionQueue;

@end

@implementation YCDiskFileCache

+ (instancetype)fileCacheWithPath:(NSString *)fileCachePath {
    YCDiskFileCache *fileCache = [[YCDiskFileCache alloc] initWithPath:fileCachePath];
    return fileCache;
}

- (instancetype)initWithPath:(NSString *)fileCachePath {
    self = [super init];
    if (!self) {
        return nil;
    }
    _fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
    BOOL fileExists = [_fileManager fileExistsAtPath:fileCachePath isDirectory:&isDirectory];
    if (!fileExists || (fileExists && !isDirectory)) {
        if (![_fileManager createDirectoryAtPath:fileCachePath withIntermediateDirectories:YES attributes:nil error:NULL]) {
            return nil;
        }
    }
    _fileCacheDirectoryPath = fileCachePath;
    _fileManager = [NSFileManager defaultManager];
    _fileCacheOperaionQueue = dispatch_queue_create("com.yc.diskFileCache.queue", DISPATCH_QUEUE_SERIAL);
    return self;
}

#pragma mark - public methods

- (void)storeData:(NSData *)data forKey:(NSString *)key {
    if (IS_EMPTY_STRING(key)) {
        return;
    }
    if (!data || data.length == 0) {
        return;
    }
    dispatch_async(self.fileCacheOperaionQueue, ^{
        NSString *filePath = [self filePathWithName:key];
        [data writeToFile:filePath atomically:YES];
    });
}

- (NSData *)dataForKey:(NSString *)key {
    if (IS_EMPTY_STRING(key)) {
        return nil;
    }
    __block NSData *data;
    dispatch_sync(self.fileCacheOperaionQueue, ^{
        NSString *filePath = [self filePathWithName:key];
        data = [NSData dataWithContentsOfFile:filePath];
    });
    return data;
}

- (void)deleteDataForKey:(NSString *)key {
    if (IS_EMPTY_STRING(key)) {
        return;
    }
    dispatch_async(self.fileCacheOperaionQueue, ^{
        NSString *filePath = [self filePathWithName:key];
        if ([self.fileManager fileExistsAtPath:filePath]) {
            [self.fileManager removeItemAtPath:filePath error:NULL];
        }
    });
}

- (void)cleanAllData {
    dispatch_async(self.fileCacheOperaionQueue, ^{
        NSArray *fileNamesArray = [self.fileManager contentsOfDirectoryAtPath:self.fileCacheDirectoryPath error:NULL];
        for (NSString *fileName in fileNamesArray) {
            NSString *filePath = [self filePathWithName:fileName];
            [self.fileManager removeItemAtPath:filePath error:NULL];
        }
    });
}

- (void)cleanDataBeforeTimestamp:(NSTimeInterval)timestamp {
    dispatch_async(self.fileCacheOperaionQueue, ^{
        NSArray *fileNamesArray = [self.fileManager contentsOfDirectoryAtPath:self.fileCacheDirectoryPath error:NULL];
        for (NSString *fileName in fileNamesArray) {
            NSString *filePath = [self filePathWithName:fileName];
            NSDictionary *fileAttributes = [self.fileManager attributesOfItemAtPath:filePath error:NULL];
            NSTimeInterval fileModificationTimestamp = [[fileAttributes fileModificationDate] timeIntervalSince1970];
            if (fileModificationTimestamp <= timestamp) {
                [self.fileManager removeItemAtPath:filePath error:NULL];
            }
        }
    });
}

#pragma mark - private methods

- (NSString *)filePathWithName:(NSString *)fileName {
    return [self.fileCacheDirectoryPath stringByAppendingPathComponent:fileName];
}

@end
