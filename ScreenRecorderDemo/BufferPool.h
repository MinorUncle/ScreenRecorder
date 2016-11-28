//
//  BufferPool.h
//  ScreenRecorderDemo
//
//  Created by mac on 16/11/28.
//  Copyright © 2016年 zhouguangjin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GJQueue+CPlus.h"

@interface BufferPool : NSObject
+(GJBuffer*)getBufferWithSize:(int)size;
+(void)setBuffer:(GJBuffer)buffer;
+(void)cleanPool;
@end
