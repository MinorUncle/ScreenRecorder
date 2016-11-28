//
//  ImageTool.h
//  ScreenRecorderDemo
//
//  Created by mac on 16/11/18.
//  Copyright © 2016年 lezhixing. All rights reserved.
//



#import <Foundation/Foundation.h>

@interface ImageTool : NSObject {
    
}

+ (NSData *) convertUIImageToBitmapRGBA8:(UIImage *)image;
+ (NSData *) convertUIImageToBitmapYUV240P:(UIImage *)image;

+ (UIImage *) convertBitmapRGBA8ToUIImage:(unsigned char *)buffer width:(int)width height:(int)height;
+ (UIImage *) convertBitmapYUV420PToUIImage:(uint8_t*)yuvData width:(int)width height:(int)height;

+(UIImage *) glToUIImageWithRect:(CGRect)rect ;

+(void)yuv2rgba8WithBuffer:(uint8_t*)yuv width:(int)width height:(int)height rgbOut:(uint8_t*)rgbaOut;
+(void)rgba2yuvWithBuffer:(uint8_t*)rgba width:(int)width height:(int)height yuvOut:(uint8_t**)yuvOut;
@end


