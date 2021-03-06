//
//  GCDTimer.h
//  LarkRA
//
//  Created by 赵天禹 on 2022/5/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GCDTimer : NSObject

/// 启动一个timer
/// @param timerId timer 的唯一标识符
/// @param start 几秒后开始执行任务
/// @param interval 每隔几秒执行一次任务
/// @param repeats 是否循环调用
/// @param async 是否异步执行任务
/// @param task 要执行的任务
+ (void)scheduledTimer:(NSString *)timerId
                 start:(NSTimeInterval)start
              interval:(NSTimeInterval)interval
               repeats:(BOOL)repeats
                 async:(BOOL)async
                  task:(dispatch_block_t)task;


/// 取消某个timer
/// @param timerId timer 的唯一标识符
+ (void)stopTimer:(NSString *)timerId;

+ (BOOL)isRuningForTimer:(NSString *)timerId;


@end

NS_ASSUME_NONNULL_END
