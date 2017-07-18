//
//  GJQueue.h
//  GJQueue
//
//  Created by tongguan on 16/3/15.
//  Copyright © 2016年 MinorUncle. All rights reserved.
//


#ifndef GJQueue_h
#define GJQueue_h
#include <stdio.h>
#include <pthread.h>
#include <assert.h>
#include <sys/time.h>
#ifdef DEBUG
#define GJQueueLOG(format, ...) NSLog(format,##__VA_ARGS__)
#else
#define GJQueueLOG(format, ...)
#endif

#define DEFAULT_MAX_COUNT 10
#define DEFAULT_WAIT_TIME 1000



@interface  GJQueue:NSObject{

    NSMutableArray* buffer;
    long _inPointer;
    long _outPointer;
    int _capacity;
    int _allocSize;
    
    NSLock* _lock;
    NSCondition* _outCond;
    NSCondition* _inCond;
}

    bool _unLock(pthread_mutex_t* mutex);
    void _init();
    void _resize();

#pragma mark DELEGATE

@property(nonatomic,assign)BOOL autoResize;


-(BOOL) getValueWithIndex:(const long)index vulue:(id*)value;

- (instancetype)initWithCapacity:(int)capacity;
-(BOOL)queuePop:(id*)temBuffer limit:(NSTimeInterval)limitDuration;
-(BOOL)queuePush:(id)temBuffer limit:(NSTimeInterval)limitDuration;
-(void) clean;
-(int)currentLenth;
@end


#endif /* GJQueue_h */
