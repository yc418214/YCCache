//
//  YCCacheMacro.h
//  YCCache
//
//  Created by 陈煜钏 on 2018/1/22.
//  Copyright © 2018年 陈煜钏. All rights reserved.
//

#ifndef YCCacheMacro_h
#define YCCacheMacro_h

#define IS_EMPTY_STRING(__string)           ((!__string) || (__string.length == 0))

#define SEMAPHORE_LOCK(_semaphore)     dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
#define SEMAPHORE_UNLOCK(_semaphore)   dispatch_semaphore_signal(_semaphore);

#ifdef DEBUG

#define YCLog(fmt, ...)                  NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

#else

#define YCLog(fmt, ...)

#endif

#endif /* YCCacheMacro_h */
