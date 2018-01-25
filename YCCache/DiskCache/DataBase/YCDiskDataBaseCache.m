//
//  YCDiskDataBaseCache.m
//  YCCache
//
//  Created by 陈煜钏 on 2018/1/22.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import "YCDiskDataBaseCache.h"

#import <sqlite3.h>
//macro
#import "YCCacheMacro.h"

static NSString * const kDBFileName = @"manifest.sqlite";
static NSString * const kDBShmFileName = @"manifest.sqlite-shm";
static NSString * const kDBWalFileName = @"manifest.sqlite-wal";

static NSString * const kDBTableName = @"manifest";

static NSUInteger const kDataBaseOpenMaxRetryCount = 6;

@interface YCDiskDataBaseCache ()

@property (strong, nonatomic) NSFileManager *fileManager;

@property (copy, nonatomic) NSString *dataBaseCachePath;

- (BOOL)openDataBase;
- (BOOL)closeDataBase;
- (BOOL)dataBaseInitialize;

- (void)dataBaseSaveData:(NSData *)data forKey:(NSString *)key;
- (NSData *)dataBaseDataForKey:(NSString *)key;
- (void)dataBaseCleanDataForKey:(NSString *)key;
- (void)dataBaseCleanDataBeforeTimestamp:(NSTimeInterval)timestamp;

@end

@implementation YCDiskDataBaseCache {
    sqlite3 *dataBase;
    CFMutableDictionaryRef stmtCache;
    NSUInteger dataBaseOpenFailedCount;
}

+ (instancetype)dataBaseCacheWithPath:(NSString *)dataBaseCachePath {
    return [[self alloc] initWithPath:dataBaseCachePath];
}

- (instancetype)initWithPath:(NSString *)dataBaseCachePath {
    self = [super init];
    if (!self) {
        return nil;
    }
    _fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
    BOOL fileExists = [_fileManager fileExistsAtPath:dataBaseCachePath isDirectory:&isDirectory];
    if (!fileExists || (fileExists && !isDirectory)) {
        if (![_fileManager createDirectoryAtPath:dataBaseCachePath withIntermediateDirectories:YES attributes:nil error:NULL]) {
            return nil;
        }
    }
    _dataBaseCachePath = dataBaseCachePath;
    
    if (![self openDataBase] || ![self dataBaseInitialize]) {
        [self closeDataBase];
        [self reset];
        if (![self openDataBase] || ![self dataBaseInitialize]) {
            [self closeDataBase];
            return nil;
        }
    }
    
    return self;
}

#pragma mark - public methods

- (void)storeData:(NSData *)data forKey:(NSString *)key {
    [self dataBaseSaveData:data forKey:key];
}

- (NSData *)dataForKey:(NSString *)key {
    return [self dataBaseDataForKey:key];
}

- (void)deleteDataForKey:(NSString *)key {
    [self dataBaseCleanDataForKey:key];
}

- (void)cleanAllData {
    [self reset];
}

- (void)cleanDataBeforeTimestamp:(NSTimeInterval)timestamp {
    [self dataBaseCleanDataBeforeTimestamp:timestamp];
}

- (void)reset {
    [self.fileManager removeItemAtPath:[self.dataBaseCachePath stringByAppendingPathComponent:kDBFileName] error:nil];
    [self.fileManager removeItemAtPath:[self.dataBaseCachePath stringByAppendingPathComponent:kDBShmFileName] error:nil];
    [self.fileManager removeItemAtPath:[self.dataBaseCachePath stringByAppendingPathComponent:kDBWalFileName] error:nil];
}

#pragma mark - private methods

- (void)releaseStmtCache {
    if (stmtCache) {
        CFRelease(stmtCache);
        stmtCache = NULL;
    }
}

#pragma mark - DataBase

- (BOOL)openDataBase {
    if (dataBase) {
        return YES;
    }
    NSString *dataBasePath = [self.dataBaseCachePath stringByAppendingPathComponent:kDBFileName];
    int openResult = sqlite3_open(dataBasePath.UTF8String, &dataBase);
    if (openResult != SQLITE_OK) {
        dataBase = NULL;
        dataBaseOpenFailedCount++;
        [self releaseStmtCache];
        
        YCLog(@"sqlite open failed");
        return NO;
    }
    CFDictionaryValueCallBacks valueCallbacks = { 0 };
    stmtCache  = CFDictionaryCreateMutable(CFAllocatorGetDefault(),
                                           0,
                                           &kCFTypeDictionaryKeyCallBacks,
                                           &valueCallbacks);
    dataBaseOpenFailedCount = 0;
    return YES;
}

- (BOOL)closeDataBase {
    if (!dataBase) {
        return YES;
    }
    [self releaseStmtCache];
    
    BOOL retry = NO;
    int result = 0;
    BOOL stmtFinalized = NO;
    do {
        retry = NO;
        result = sqlite3_close(dataBase);
        if (result == SQLITE_BUSY || result == SQLITE_LOCKED) {
            if (!stmtFinalized) {
                stmtFinalized = YES;
                sqlite3_stmt *stmt;
                while ((stmt = sqlite3_next_stmt(dataBase, nil)) != 0) {
                    sqlite3_finalize(stmt);
                    retry = YES;
                }
            }
        } else if (result != SQLITE_OK) {
            YCLog(@"sqlite close failed");
        }
    } while (retry);
    
    dataBase = NULL;
    return NO;
}

- (BOOL)dataBaseInitialize {
    NSString *createTableSqlString =
    [NSString stringWithFormat:@"create table if not exists %@ (key text, data blob, create_time integer, primary key(key));", kDBTableName];
    NSString *createIndexSqlString =
    [NSString stringWithFormat:@"create index if not exists create_time_idx on %@(create_time);", kDBTableName];
    NSString *sqlString =
    [NSString stringWithFormat:@"pragma journal_mode = wal; pragma synchronous = normal; %@ %@", createTableSqlString, createIndexSqlString];
    return [self dataBaseExecuteSQL:sqlString];
}

#define DATABASE_CHECK      [self dataBaseCheck]
- (BOOL)dataBaseCheck {
    if (dataBase) {
        return YES;
    }
    if (dataBaseOpenFailedCount > kDataBaseOpenMaxRetryCount) {
        return NO;
    }
    return [self openDataBase] && [self dataBaseInitialize];
}

- (void)dataBaseCheckPoint {
    if (!DATABASE_CHECK) {
        return;
    }
    sqlite3_wal_checkpoint(dataBase, NULL);
}

- (BOOL)dataBaseExecuteSQL:(NSString *)sqlString {
    if (!DATABASE_CHECK || IS_EMPTY_STRING(sqlString)) {
        return NO;
    }
    char *error;
    int executeResult = sqlite3_exec(dataBase, sqlString.UTF8String, NULL, NULL, &error);
    if (error) {
        YCLog(@"sqlite execute : %@ error : %s", sqlString, error);
        sqlite3_free(error);
    }
    return (executeResult == SQLITE_OK);
}

- (sqlite3_stmt *)dataBasePrepareStmt:(NSString *)sqlString {
    if (!DATABASE_CHECK || IS_EMPTY_STRING(sqlString) || !stmtCache) {
        return NULL;
    }
    const void *key = (__bridge const void *)sqlString;
    sqlite3_stmt *stmt = (sqlite3_stmt *)CFDictionaryGetValue(stmtCache, key);
    if (stmt) {
        sqlite3_reset(stmt);
        return stmt;
    }
    int result = sqlite3_prepare_v2(dataBase, sqlString.UTF8String, -1, &stmt, NULL);
    if (result != SQLITE_OK) {
        YCLog(@"sqlite prepare stmt for sql : %@ error : %s", sqlString, sqlite3_errmsg(dataBase));
        return NULL;
    }
    CFDictionarySetValue(stmtCache, key, stmt);
    return stmt;
}

- (void)dataBaseSaveData:(NSData *)data forKey:(NSString *)key {
    NSString *sqlString =
    [NSString stringWithFormat:@"insert or replace into %@ (key, data, create_time) values (?1, ?2, ?3);", kDBTableName];
    sqlite3_stmt *stmt = [self dataBasePrepareStmt:sqlString];
    if (!stmt) {
        return;
    }
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    sqlite3_bind_blob(stmt, 2, data.bytes, (int)data.length, NULL);
    sqlite3_bind_int(stmt, 3, (int)[[NSDate date] timeIntervalSince1970]);
    
    int result = sqlite3_step(stmt);
    if (result != SQLITE_DONE) {
        YCLog(@"sqlite save data for key : %@ error : %s", key, sqlite3_errmsg(dataBase));
    }
}

- (NSData *)dataBaseDataForKey:(NSString *)key {
    NSString *sqlString = [NSString stringWithFormat:@"select data from %@ where key = ?1;", kDBTableName];
    sqlite3_stmt *stmt = [self dataBasePrepareStmt:sqlString];
    if (!stmt) {
        return nil;
    }
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    
    int result = sqlite3_step(stmt);
    if (result != SQLITE_ROW) {
        return nil;
    }
    if (result != SQLITE_DONE) {
        NSLog(@"sqlite get data for key : %@ error : %s", key, sqlite3_errmsg(dataBase));
        return nil;
    }
    
    NSData *data = [NSData dataWithBytes:sqlite3_column_blob(stmt, 0)
                                  length:sqlite3_column_bytes(stmt, 0)];
    return data;
}

- (void)dataBaseCleanDataForKey:(NSString *)key {
    NSString *sqlString = [NSString stringWithFormat:@"delete from %@ where key = ?1;", kDBTableName];
    sqlite3_stmt *stmt = [self dataBasePrepareStmt:sqlString];
    if (!stmt) {
        return;
    }
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    
    int result = sqlite3_step(stmt);
    if (result != SQLITE_DONE) {
        YCLog(@"sqlite clean data for key : %@ error : %s", key, sqlite3_errmsg(dataBase));
    }
}

- (void)dataBaseCleanDataBeforeTimestamp:(NSTimeInterval)timestamp {
    NSString *sqlString = [NSString stringWithFormat:@"delete from %@ where create_time < ?1;", kDBTableName];
    sqlite3_stmt *stmt = [self dataBasePrepareStmt:sqlString];
    if (!stmt) {
        return;
    }
    sqlite3_bind_int(stmt, 1, (int)timestamp);
    
    int result = sqlite3_step(stmt);
    if (result != SQLITE_DONE) {
        YCLog(@"sqlite clean data before timestamp : %zd error : %s", (NSInteger)timestamp, sqlite3_errmsg(dataBase));
    }
}

@end
