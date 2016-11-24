//
//  GJH264Encoder.h
//  视频录制
//
//  Created by tongguan on 15/12/28.
//  Copyright © 2015年 未成年大叔. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import "GJFormats.h"

@class GJH264Encoder;
@protocol GJH264EncoderDelegate <NSObject>
-(void)GJH264Encoder:(GJH264Encoder*)encoder encodeCompleteBuffer:(uint8_t*)buffer withLenth:(long)totalLenth keyFrame:(BOOL)keyFrame dts:(int64_t)dts;
@end
@interface GJH264Encoder : NSObject
@property(nonatomic,weak)id<GJH264EncoderDelegate> deleagte;
@property(nonatomic,readonly,retain)NSData* parameterSet;
//@property(assign,nonatomic) int32_t currentWidth;
//@property(assign,nonatomic) int32_t currentHeight;
-(void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer fourceKey:(BOOL)fourceKey;
-(void)encodeImageBuffer:(CVImageBufferRef)imageBuffer fourceKey:(BOOL)fourceKey;

//@property(assign,nonatomic) int32_t bitRate;
//@property(assign,nonatomic) int32_t maxKeyFrameInterval;//gop_size
@property(assign,nonatomic) float quality;//
//@property(assign,nonatomic) CFStringRef profileLevel;//
//@property(assign,nonatomic) CFStringRef entropyMode;//
//@property(assign,nonatomic) BOOL allowBFrame;//
//@property(assign,nonatomic) BOOL allowPFrame;//

@property(assign,nonatomic)H264Format destFormat;

@property(assign,nonatomic) int expectedFrameRate;//

-(instancetype)initWithFps:(uint)fps;

-(void)stop;
@end

//void praseVideoParamet(uint8_t* inparameterSet,uint8_t** inoutSetArry,int* inoutArryCount){
//    
//}
