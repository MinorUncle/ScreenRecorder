//
//  GJH264Decoder.h
//  视频录制
//
//  Created by tongguan on 15/12/28.
//  Copyright © 2015年 未成年大叔. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import "GJFormats.h"
@class GJH264Decoder;
@protocol GJH264DecoderDelegate <NSObject>
-(void)GJH264Decoder:(GJH264Decoder*)devocer decodeCompleteImageData:(CVImageBufferRef)imageBuffer pts:(uint)pts;
@end

@interface GJH264Decoder : NSObject

@property(nonatomic,weak)id<GJH264DecoderDelegate> delegate;
-(void)decodeBuffer:(uint8_t*)buffer withLenth:(uint32_t)totalLenth;

@end
