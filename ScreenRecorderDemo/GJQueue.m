//
//  GJQueue.m
//  ScreenRecorderDemo
//
//  Created by mac on 16/11/22.
//  Copyright © 2016年 zhouguangjin. All rights reserved.
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
        [self _init];
    }
    return self;
}
- (instancetype)init
{
    return [self initWithCapacity:DEFAULT_MAX_COUNT];
}

-(void)_init
{
    buffer = [NSMutableArray arrayWithCapacity:_capacity];
    _lock = [[NSLock alloc]init];
    _inCond = [[NSCondition alloc]init];
    _outCond = [[NSCondition alloc]init];
    _allocSize = _capacity;
    _autoResize = false;
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
        [_outCond lock];
        BOOL result = [_outCond waitUntilDate: [NSDate dateWithTimeIntervalSinceNow:limitDuration]];
        [_outCond unlock];
        if (!result) {
            return false;
        }
        [_lock lock];
    }
    
    
    *temBuffer = buffer[_outPointer%_allocSize];
    buffer[_outPointer%_allocSize] = placeholder;
    _outPointer++;
    [_inCond lock];
    [_inCond signal];
    [_inCond unlock];
    [_lock unlock];
    assert(*temBuffer);
    return true;
}



-(BOOL)queuePush:(id)temBuffer limit:(NSTimeInterval)limitDuration{
    
    [_lock lock];
    if ((_inPointer % _allocSize == _outPointer % _allocSize && _inPointer > _outPointer)) {
        if (_autoResize) {
            [self _resize];
        }else{
            [_lock unlock];
            
            [_inCond lock];
            BOOL result = [_inCond waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:limitDuration]];
            [_inCond unlock];
            if (!result) {
                return false;
            }
            [_lock lock];
        }
    }
    
    buffer[_inPointer%_allocSize] = temBuffer;
    
    _inPointer++;
    [_outCond lock];
    [_outCond signal];
    [_outCond unlock];
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
    [_inCond lock];
    [_inCond signal];
    [_inCond unlock];
    [_lock unlock];
}


@end
