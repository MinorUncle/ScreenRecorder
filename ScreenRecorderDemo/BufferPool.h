//
//  BuffelPool.h
//  ScreenRecorderDemo
//
//  Created by mac on 16/11/29.
//  Copyright © 2016年 zhouguangjin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Buffer : NSObject
@property(assign,nonatomic)uint8_t* data;
@property(assign,nonatomic)size_t size;
- (instancetype)initWithBuffer:(uint8_t*)data size:(size_t)size;
@end


@interface BufferPool : NSObject
+(instancetype)shareBufferPool;//共享pool 
-(Buffer*)bufferWithSize:(size_t)size;
-(void)setBufferWithBuffer:(Buffer*)buffer;
@end
