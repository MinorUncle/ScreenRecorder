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

/** Converts a UIImage to RGBA8 bitmap.
 @param image - a UIImage to be converted
 @return a RGBA8 bitmap, or NULL if any memory allocation issues. Cleanup memory with free() when done.
 */
+ (NSData *) convertUIImageToBitmapRGBA8:(UIImage *)image;
+ (NSData *) convertUIImageToBitmapYUV240P:(UIImage *)image;

/** A helper routine used to convert a RGBA8 to UIImage
 @return a new context that is owned by the caller
 */
+ (CGContextRef) newBitmapRGBA8ContextFromImage:(CGImageRef)image;


/** Converts a RGBA8 bitmap to a UIImage.
 @param buffer - the RGBA8 unsigned char * bitmap
 @param width - the number of pixels wide
 @param height - the number of pixels tall
 @return a UIImage that is autoreleased or nil if memory allocation issues
 */
+ (UIImage *) convertBitmapRGBA8ToUIImage:(unsigned char *)buffer
                                withWidth:(int)width
                               withHeight:(int)height;

+(UIImage *) glToUIImageWithRect:(CGRect)rect ;
-(UIImage *)mergerImage:(UIImage *)firstImage fristPoint:(CGPoint)fristPoint secodImage:(UIImage *)secondImage secondPoint:(CGPoint)secondPoint destSize:(CGSize)destSize;

@end


