//
//  BufferPool+CPlus.c
//  ScreenRecorderDemo
//
//  Created by mac on 16/11/30.
//  Copyright © 2016年 zhouguangjin. All rights reserved.
//

#include "BufferPool+CPlus.h"
GJBuffer::GJBuffer(int8_t* bufferData,int bufferSize){
    static int i = 0;
    printf("GJBuffer count:%d\n",++i);
    data = bufferData;
    size = _capacity = bufferSize;
}
GJBuffer::GJBuffer(){
    data = NULL;
    size = _capacity = 0;
}
int GJBuffer::capacity(){
    return _capacity;
}

BufferPool::BufferPool(){
    _cacheQueue.autoResize = true;
    _cacheQueue.shouldNonatomic = false;
    _cacheQueue.shouldWait = false;    
}

BufferPool* BufferPool::defaultBufferPool()
{
    static BufferPool* _defaultPool = new BufferPool();
    return _defaultPool;
}

GJBuffer* BufferPool::getBuffer(int size){
    static int mc = 0;
    GJBuffer* buffer = NULL;
    if(_cacheQueue.queuePop(&buffer)) {
        if (buffer->_capacity < size) {
            free(buffer->data);
            buffer->data = (int8_t*)malloc(size);
            printf("malloc GJBuffer0 count:%d\n",++mc);

            buffer->size = buffer->_capacity = size;
        }else{
            buffer->size = size;
        }

    }
    if (!buffer) {
        buffer = new GJBuffer((int8_t*)malloc(size),size);
        printf("malloc GJBuffer count:%d\n",++mc);
    }
    return buffer;
}

void BufferPool::setBuffer(GJBuffer* buffer){
    _cacheQueue.queuePush(buffer);
}
void BufferPool::cleanBuffer(){
    GJBuffer* buffer;
    while (_cacheQueue.queuePop(&buffer)) {
        free(buffer->data);
        free(buffer);
    }
    _cacheQueue.clean();
}
