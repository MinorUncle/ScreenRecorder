//
//  BufferPool+CPlus.h
//  ScreenRecorderDemo
//
//  Created by mac on 16/11/29.
//  Copyright © 2016年 zhouguangjin. All rights reserved.
//

#ifndef BufferPool_CPlus_h
#define BufferPool_CPlus_h
#import "GJQueue+CPlus.h"

class BufferPool;
typedef struct GJBuffer{
private:
    int _capacity;//readOnly,real data size
public:
    void* data;
    int size;
    GJBuffer(int8_t* bufferData,int bufferSize);
    GJBuffer();
    int capacity();
    friend BufferPool;
} GJBuffer;


class BufferPool {
private:
    GJQueue<GJBuffer*> _cacheQueue; //用指针，效率更高
public:
    BufferPool();//自己新建空间
    static BufferPool* defaultBufferPool();//共享的空间   //注意内存紧张时释放内存
    GJBuffer* getBuffer(int size);
    void setBuffer(GJBuffer* buffer);
    void cleanBuffer();
    ~BufferPool();
};


#endif /* BufferPool_CPlus_h */
