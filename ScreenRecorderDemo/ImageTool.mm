


#import "ImageTool.h"
#import <OpenGLES/ES2/gl.h>
#import "GJQueue+CPlus.h"

@implementation ImageTool

static GJQueue<GJBuffer*> _pixPool;


void dataProviderReleaseDataCallback(void * __nullable info,
                                     const void *  data, size_t size){
//    free((void*)data);
    _pixPool.queuePush((GJBuffer*)info);
//    NSLog(@"free dataProviderReleaseDataCallback");
}

+(UIImage *) glToUIImageWithRect:(CGRect)rect {
    rect.size.height *= [UIScreen mainScreen].scale;
    rect.size.width *= [UIScreen mainScreen].scale;
    NSInteger myDataLength = rect.size.width * rect.size.height * 4;  //1024-width，768-height
    
    // allocate array and read pixels into it.
    GJBuffer *cachebuffer = (GJBuffer *) [self getCachePixDataWithSize:(int)myDataLength];
//    GLubyte *buffer = (GLubyte *) malloc(myDataLength);
    GLubyte *buffer = (GLubyte*)(cachebuffer->data);
    glReadPixels(rect.origin.x,rect.origin.y,rect.size.width,rect.size.height, GL_RGBA, GL_UNSIGNED_BYTE, buffer);

    CGDataProviderRef provider = CGDataProviderCreateWithData(cachebuffer, buffer, myDataLength, dataProviderReleaseDataCallback);
    
    // prep the ingredients
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = 4 * rect.size.width;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    // make the cgimage
    CGImageRef imageRef = CGImageCreate(rect.size.width, rect.size.height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    // then make the uiimage from that
    UIImage *myImage = [UIImage imageWithCGImage:imageRef scale:[UIScreen mainScreen].scale orientation:UIImageOrientationDownMirrored];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    return myImage;
}
//合并图片
+(UIImage *)mergerImage:(UIImage *)firstImage fristPoint:(CGPoint)fristPoint secodImage:(UIImage *)secondImage secondPoint:(CGPoint)secondPoint destSize:(CGSize)destSize{
    
    CGSize imageSize = destSize;
    UIGraphicsBeginImageContext(imageSize);
    
    CGSize fristSize = firstImage.size;
    CGSize secondSize = secondImage.size;
    
    [firstImage drawInRect:CGRectMake(fristPoint.x, fristPoint.y, fristSize.width, fristSize.height)];
    [secondImage drawInRect:CGRectMake(secondPoint.x, secondPoint.y, secondSize.width, secondSize.height)];
    
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resultImage;
}

+ (NSData *) convertUIImageToBitmapRGBA8:(UIImage *) image {
    
    CGImageRef imageRef = image.CGImage;
    NSData* data;
    // Create a bitmap context to draw the uiimage into
    CGContextRef context = [self newBitmapRGBA8ContextFromImage:imageRef];
    
    if(!context) {
        return NULL;
    }
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    CGRect rect = CGRectMake(0, 0, width, height);
    
    CGContextDrawImage(context, rect, imageRef);
    
    unsigned char *bitmapData = (unsigned char *)CGBitmapContextGetData(context);
    
    size_t bytesPerRow = CGBitmapContextGetBytesPerRow(context);
    if(bitmapData) {
        data = [NSData dataWithBytes:bitmapData length:bytesPerRow * height];
//        free(bitmapData);
    } else {
        NSLog(@"Error getting bitmap pixel data\n");
    }
    CGContextRelease(context);
    return data;
}



+ (NSData *) convertUIImageToBitmapYUV240P:(UIImage *)image{
    NSData* rgba8 = [self convertUIImageToBitmapRGBA8:image];

   
    uint8_t* rgba = (uint8_t*)[rgba8 bytes];
    CGSize size = image.size;
    int total = size.height * size.width;
    int uvw = size.width,uvh = size.height;
#if 0
    if (uvw % 2 == 1)uvw++;
    if (uvh % 2 == 1)uvh++;
    uint8_t* blockData = (uint8_t*)malloc(total+uvw*uvh*0.5);
    uint8_t* v = blockData+ (int)(total+uvh*uvw*0.25);
#else
    //forbid singular height or width
    NSAssert(uvw % 2 == 0 && uvh % 2 == 0, @"图像宽或者高不能为奇数");
    uint8_t* blockData = (uint8_t*)malloc(total*1.5);
    uint8_t* v = blockData+ (int)(total*1.25);
#endif
    uint8_t* y = blockData;
    uint8_t* u = blockData+ (int)total;
    int uvindex=0;
    int yindex=0;
    
    for (int i = 0; i < size.height; i++) {
        for (int j=0; j < size.width; j++) {
            uint8_t r = rgba[yindex*4],g=rgba[yindex*4+1],b=rgba[yindex*4+2];
            int yy =0.2558*r + 0.502*g + 0.097*b+16 ;
            yy = MIN(yy, 255);
            y[yindex++] = yy;
            
            if (j%2==0 && i%2==0 ) {
                int uu = -0.147644*r - 0.289856*g + 0.4375*b + 128;
                uu= MAX(0, MIN(uu , 255));
                u[uvindex]=uu;
                
                int vv = 0.4375*r - 0.366352*g - 0.071148*b + 128;
                vv= MAX(0, MIN(vv , 255));
                v[uvindex++]=vv;
            }
        }
    }    
    
    NSData* data = [NSData dataWithBytesNoCopy:blockData length:total*1.5];
    return data;
}

+ (CGContextRef) newBitmapRGBA8ContextFromImage:(CGImageRef) image {
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;
//    uint32_t *bitmapData;
    
    size_t bitsPerPixel = 32;
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = bitsPerPixel / bitsPerComponent;
    
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    
    size_t bytesPerRow = width * bytesPerPixel;
//    size_t bufferLength = bytesPerRow * height;
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
    if(!colorSpace) {
        NSLog(@"Error allocating color space RGB\n");
        return NULL;
    }
    

    
    context = CGBitmapContextCreate(NULL,
                                    width,
                                    height,
                                    bitsPerComponent,
                                    bytesPerRow,
                                    colorSpace,
                                    kCGImageAlphaPremultipliedLast);	// RGBA
    if(!context) {
//        free(bitmapData);
        NSLog(@"Bitmap context not created");
    }
    
    CGColorSpaceRelease(colorSpace);
    
    return context;
}

+ (UIImage *) convertBitmapRGBA8ToUIImage:(unsigned char *) buffer
                                withWidth:(int) width
                               withHeight:(int) height {
    
    
    size_t bufferLength = width * height * 4;
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, bufferLength, NULL);
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = 4 * width;
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    if(colorSpaceRef == NULL) {
        NSLog(@"Error allocating color space");
        CGDataProviderRelease(provider);
        return nil;
    }
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGImageRef iref = CGImageCreate(width,
                                    height,
                                    bitsPerComponent,
                                    bitsPerPixel,
                                    bytesPerRow,
                                    colorSpaceRef,
                                    bitmapInfo,
                                    provider,	// data provider
                                    NULL,		// decode
                                    YES,			// should interpolate
                                    renderingIntent);
    
    GJBuffer* pixels = (GJBuffer*)[self getCachePixDataWithSize:(int)bufferLength];
    
    if(pixels == NULL) {
        NSLog(@"Error: Memory not allocated for bitmap");
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpaceRef);
        CGImageRelease(iref);
        return nil;
    }
    
    CGContextRef context = CGBitmapContextCreate(pixels->data,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpaceRef,
                                                 kCGImageAlphaPremultipliedLast);
    
    if(context == NULL) {
        NSLog(@"Error context not created");
        _pixPool.queuePush(pixels);
    }
    
    UIImage *image = nil;
    if(context) {
        
        CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), iref);
        
        CGImageRef imageRef = CGBitmapContextCreateImage(context);
        
        // Support both iPad 3.2 and iPhone 4 Retina displays with the correct scale
        if([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)]) {
            float scale = [[UIScreen mainScreen] scale];
            image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
        } else {
            image = [UIImage imageWithCGImage:imageRef];
        }
        
        CGImageRelease(imageRef);
        CGContextRelease(context);
    }
    
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(iref);
    CGDataProviderRelease(provider);
    free(pixels->data);
    free(pixels);
    return image;
}
+ (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image
{
    CGSize frameSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:NO], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:NO], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width,
                                          frameSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, frameSize.width,
                                                 frameSize.height, 8, 4*frameSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipLast);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), 
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    return pxbuffer;
}
+(GJBuffer*)getCachePixDataWithSize:(int)size{
    GJBuffer* buffer = NULL;
    if(_pixPool.queuePop(&buffer)){
        if (size > buffer->size) {
            free(buffer->data);
            void* data = (void*)malloc(size);
            buffer->data = data;
            buffer->size = size;
        }
    }else{
        buffer = new GJBuffer();
        void* data = (void*)malloc(size);
        buffer->data = data;
        buffer->size = size;
    }
    return buffer;
}
+(void)cleanPixCache{
    
    GJBuffer * buffer = NULL;
    while (_pixPool.queuePop(&buffer)) {
        free(buffer->data);
        free(buffer);
    }
}
@end
