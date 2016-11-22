//
//  GJQueue.m
//  ScreenRecorderDemo
//
//  Created by mac on 16/11/22.
//  Copyright © 2016年 lezhixing. All rights reserved.
//

#import "GJQueue.h"
@implementation GJQueue
static id placeholder = @"NULL";//数组中占位符
- (instancetype)initWithCapacity:(int)capacity
{
    self = [super init];
    if (self) {
        _capacity = capacity;
        if (capacity <=0) {
            _capacity = DEFAULT_MAX_COUNT;
        }
    }
    return self;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        _capacity = DEFAULT_MAX_COUNT;
        [self _init];
    }
    return self;
}

-(void)_init
{
    buffer = [NSMutableArray arrayWithCapacity:_capacity];
    
    _lock = [[NSLock alloc]init];
    _inCond = [[NSCondition alloc]init];
    _outCond = [[NSCondition alloc]init];
    _allocSize = _capacity;
    _autoResize = false;
    _shouldWait = false;
    _shouldNonatomic = false;
    _inPointer = 0;
    _outPointer = 0;
    
}


-(int)currentLenth{
    [_lock lock];
    int lenth = (int)(_inPointer - _outPointer);
    [_lock unlock];
    return lenth;
}

-(BOOL) getValueWithIndex:(const long)index vulue:(id*)value{
    [_lock lock];
    long inpoint = _inPointer%_allocSize;
    long outpoint = _outPointer%_allocSize;
    long current = index%_allocSize;
    if (current >= inpoint || current < outpoint) {
        [_lock unlock];
        return false;
    }
    *value = buffer[current];
    [_lock unlock];
    return true;
}



-(BOOL)queuePop:(id*)temBuffer limit:(NSTimeInterval)limitDuration{
    [_lock lock];
    if (_inPointer <= _outPointer) {
        [_lock unlock];
        GJQueueLOG("begin Wait in ----------\n");
        NSDate* fireDate = [NSDate dateWithTimeIntervalSinceNow:limitDuration];
        [_outCond lock];
        BOOL result = [_outCond waitUntilDate:fireDate];
        [_outCond unlock];
        if (!result) {
            GJQueueLOG("fail Wait in ----------\n");
            return false;
        }
        [_lock lock];
        GJQueueLOG("after Wait in.  incount:%ld  outcount:%ld----------\n",_inPointer,_outPointer);
    }
    
    
    *temBuffer = buffer[_outPointer%_allocSize];
    buffer[_outPointer%_allocSize] = placeholder;
    _outPointer++;
    [_inCond lock];
    [_inCond signal];
    [_inCond unlock];
    GJQueueLOG("after signal out.  incount:%ld  outcount:%ld----------\n",_inPointer,_outPointer);
    [_lock unlock];
    return true;
}



-(BOOL)queuePush:(id)temBuffer limit:(NSTimeInterval)limitDuration{
    
    [_lock lock];
    if ((_inPointer % _allocSize == _outPointer % _allocSize && _inPointer > _outPointer)) {
        if (_autoResize) {
            [self _resize];
        }else{
            [_lock unlock];
            
            GJQueueLOG("begin Wait out ----------\n");
            NSDate* fireDate = [NSDate dateWithTimeIntervalSinceNow:limitDuration];
            [_inCond lock];
            BOOL result = [_inCond waitUntilDate:fireDate];
            [_inCond unlock];
            if (!result) {
                GJQueueLOG("fail begin Wait out ----------\n");
                return false;
            }
            [_lock lock];
            GJQueueLOG("after Wait out.  incount:%ld  outcount:%ld----------\n",_inPointer,_outPointer);
        }
    }
    
    NSLog(@"tembuffer:%ld %@",_inPointer%_allocSize,temBuffer);
    buffer[_inPointer%_allocSize] = temBuffer;
    
    _inPointer++;
    [_outCond lock];
    [_outCond signal];
    [_outCond unlock];
    GJQueueLOG("after signal in. incount:%ld  outcount:%ld----------\n",_inPointer,_outPointer);
    [_lock unlock];
    return true;
}

-(void)_resize{
    int resize = _allocSize * 2;
    NSMutableArray* temArry = [NSMutableArray arrayWithCapacity:resize];
    
    
        for (long i = _outPointer,j =0; i<_inPointer; i++,j++) {
            temArry[j] = buffer[i%_allocSize];
        }
        buffer = temArry;
        _inPointer = _allocSize;
        _outPointer = 0;
        _allocSize = resize;
}
-(void)clean{
    [_lock lock];
    for (long i = _outPointer; i < _inPointer ; i++) {
        buffer[i%_allocSize] = placeholder;
    }
    _inPointer=_outPointer=0;
    [_lock unlock];
}


@end
