//
//  NSDate+YCAddition.m
//  YCCache
//
//  Created by 陈煜钏 on 2018/1/22.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#import "NSDate+YCAddition.h"

@implementation NSDate (YCAddition)

+ (instancetype)yc_today {
    NSString *todayString = [[self yc_simpleDateFormatter] stringFromDate:[NSDate date]];
    return [[self yc_standardDateFormatter] dateFromString:[NSString stringWithFormat:@"%@ 00:00:00", todayString]];
}

#pragma mark - private methods

+ (NSDateFormatter *)yc_standardDateFormatter {
    static NSDateFormatter *standardDateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        standardDateFormatter = [[NSDateFormatter alloc] init];
        standardDateFormatter.dateFormat = @"YYYY-MM-dd HH:mm:ss";
    });
    return standardDateFormatter;
}

+ (NSDateFormatter *)yc_simpleDateFormatter {
    static NSDateFormatter *simpleDateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        simpleDateFormatter = [[NSDateFormatter alloc] init];
        simpleDateFormatter.dateFormat = @"YYYY-MM-dd";
    });
    return simpleDateFormatter;
}

@end
