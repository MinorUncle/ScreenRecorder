////
////  BufferPool.m
////  ScreenRecorderDemo
////
////  Created by mac on 16/11/28.
////  Copyright © 2016年 zhouguangjin. All rights reserved.
////
//
//#import "BufferPool.h"
//static GJQueue<GJBuffer*> _pixPool;
//
//@implementation BufferPool
//+(GJBuffer*)getBufferWithSize:(int)size{
//    GJBuffer* buffer = NULL;
//    if(_pixPool.queuePop(&buffer)){
//        if (size > buffer->size) {
//            free(buffer->data);
//            void* data = (void*)malloc(size);
//            buffer->data = data;
//            buffer->size = size;
//        }
//    }else{
//        buffer = new GJBuffer();
//        void* data = (void*)malloc(size);
//        buffer->data = data;
//        buffer->size = size;
//    }
//    return buffer;
//}
//+(void)cleanPool{
//    
//    GJBuffer * buffer = NULL;
//    while (_pixPool.queuePop(&buffer)) {
//        free(buffer->data);
//        free(buffer);
//    }
//}
//@end
