//
//  BuffelPool.m
//  ScreenRecorderDemo
//
//  Created by mac on 16/11/29.
//  Copyright © 2016年 zhouguangjin. All rights reserved.
//

#import "BufferPool.h"
#import "GJQueue.h"


@interface Buffer()
@property(assign,nonatomic)size_t capacity;
@end
@implementation Buffer
- (instancetype)initWithBuffer:(uint8_t*)data size:(size_t)size;
{
    self = [super init];
    if (self) {
        _data = data;
        _size=_capacity=size;
    }
    return self;
}

-(NSString *)description{
    return [NSString stringWithFormat:@"buffer:%p size:%zu,captacity:%zu",self,_size,_capacity];
}
@end

@interface BufferPool ()
@property(strong,nonatomic) GJQueue* bufferCache;

@end

@implementation BufferPool

static BufferPool* _shareBuffer;
- (instancetype)init
{
    self = [super init];
    if (self) {
        _bufferCache = [[GJQueue alloc]initWithCapacity:10];
        [_bufferCache setAutoResize:YES];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(clean) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        
    }
    return self;
}
+(instancetype)shareBufferPool{
    if (_shareBuffer == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _shareBuffer = [[BufferPool alloc]init];
        });
        
    }
    return _shareBuffer;
}

-(Buffer*)bufferWithSize:(size_t)size{
    Buffer* rBuffer = nil;
    while ([self.bufferCache queuePop:&rBuffer limit:0]) {
        if (rBuffer.capacity<size) {
            free(rBuffer.data);
            rBuffer = nil;
        }else{
            rBuffer.size=size;
            break;
        }
    }
    if (!rBuffer) {
        rBuffer = [[Buffer alloc]initWithBuffer:(uint8_t *)malloc(size) size:size];
    }
    return rBuffer;
}
-(void)setBufferWithBuffer:(Buffer*)buffer{
    [_bufferCache queuePush:buffer limit:0];
}
-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(void)clean{
    Buffer* rBuffer = nil;
    while ([self.bufferCache queuePop:&rBuffer limit:0]) {
        free(rBuffer.data);
    }
    [self.bufferCache clean];
}
@end
