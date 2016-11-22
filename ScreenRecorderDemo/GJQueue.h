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
    long _inPointer;  //尾
    long _outPointer; //头,出的位置,左出右进
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


    /**
     *  //自定义深复制，比如需要复制结构体里面的指针需要复制，为空时则直接赋值指针；
     *dest 为目标地址，soc是赋值源
     */

@property(nonatomic,assign)BOOL shouldWait;  //没有数据时是否支持等待，当为autoResize 为YES时，push永远不会等待
@property(nonatomic,assign)BOOL shouldNonatomic; //是否多线程，
@property(nonatomic,assign)BOOL autoResize;    //是否支持自动增长，当为YES时，push永远不会等待，只会重新申请内存,默认为false

    //根据index获得value,当超过_inPointer和_outPointer范围则失败，用于遍历数组，不会产生进出队列作用
-(BOOL) getValueWithIndex:(const long)index vulue:(id*)value;

- (instancetype)initWithCapacity:(int)capacity;
//limit < 0 not wait;,unit /seconde
-(BOOL)queuePop:(id*)temBuffer limit:(NSTimeInterval)limitDuration;
-(BOOL)queuePush:(id)temBuffer limit:(NSTimeInterval)limitDuration;
-(void) clean;//主要用于线程等待时清除数据
-(int)currentLenth;
@end



//template<class T>
//bool GJQueue<T>::_mutexWait(pthread_cond_t* _cond,int inTimeoutInMilSecs)
//{
//    if (!shouldWait) {
//        return false;
//    }
//    pthread_mutex_lock(&_mutex);
//    
//    struct timespec ts;
//    struct timeval tv;
//    struct timezone tz;
//    int sec, usec;
//    
//    //These platforms do refcounting manually, and wait will release the mutex,
//    // so we need to update the counts here
//    
//    
//    bool result = true;
//    if (inTimeoutInMilSecs == 0)
//        (void)pthread_cond_wait(_cond, &_mutex);
//    else
//    {
//        gettimeofday(&tv, &tz);
//        sec = inTimeoutInMilSecs / 1000;
//        inTimeoutInMilSecs = inTimeoutInMilSecs - (sec * 1000);
//        assert(inTimeoutInMilSecs < 1000);
//        usec = inTimeoutInMilSecs * 1000;
//        assert(tv.tv_usec < 1000000);
//        ts.tv_sec = tv.tv_sec + sec;
//        ts.tv_nsec = (tv.tv_usec + usec) * 1000;
//        assert(ts.tv_nsec < 2000000000);
//        if(ts.tv_nsec > 999999999)
//        {
//            ts.tv_sec++;
//            ts.tv_nsec -= 1000000000;
//        }
//        int ret = pthread_cond_timedwait(_cond, &_mutex, &ts);
//        result = !(ret == ETIMEDOUT);
//
//    }
////    pthread_cond_wait(_cond, &_mutex);
//    pthread_mutex_unlock(&_mutex);
//    return result;
//}
//template<class T>
//bool GJQueue<T>::_mutexSignal(pthread_cond_t* _cond)
//{
//    if (!shouldWait) {
//        return false;
//    }
//    pthread_mutex_lock(&_mutex);
//    pthread_cond_signal(_cond);
//    pthread_mutex_unlock(&_mutex);
//    return true;
//}
//template<class T>
//bool GJQueue<T>::_lock(pthread_mutex_t* mutex){
//    if (!shouldNonatomic) {
//        return false;
//    }
//    return !pthread_mutex_lock(mutex);
//}
//template<class T>
//bool GJQueue<T>::_unLock(pthread_mutex_t* mutex){
//    if (!shouldNonatomic) {
//        return false;
//    }
//    return !pthread_mutex_unlock(mutex);
//}
//template<class T>

#endif /* GJQueue_h */
