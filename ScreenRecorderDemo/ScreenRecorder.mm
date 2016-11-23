//
//  ScreenRecorder.m
//  ScreenRecorderDemo
//
//  Created by mac on 16/11/17.
//  Copyright © 2016年 lezhixing. All rights reserved.
//

#import "ScreenRecorder.h"
#import "GJQueue.h"
#import <AVFoundation/AVFoundation.h>
#import <OpenGLES/ES2/gl.h>
#import "ImageTool.h"


@interface ScreenRecorder()<GJH264EncoderDelegate>
{
    GJQueue* _imageCache;//有问题
    dispatch_queue_t _writeQueue;
    dispatch_queue_t _captureQueue;
    NSDictionary* _options;//cache
    CVPixelBufferRef _pixelBuffer ;//cache
    NSInteger* _totalCount;
    CFRunLoopRef _captureRunLoop;
    CGRect _glRect;
    BOOL _mixtureRecorder;
    

//    NSMutableArray* _cacheArry;//效率很低，待改善
}
@property(strong,nonatomic)NSTimer* fpsTimer;

@end

@implementation ScreenRecorder
- (instancetype)initWithType:(ScreenRecorderType)recorderType
{
    self = [super init];
    if (self) {
        _captureQueue = dispatch_queue_create("captureQueue", DISPATCH_QUEUE_SERIAL);
        
        _recorderType = recorderType;
        _imageCache = [[GJQueue alloc]init];
        _imageCache.autoResize = false;
        
   
    
        
        _options = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                    [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];

//        _cacheArry = [NSMutableArray arrayWithCapacity:20];
 
    }
    return self;
}

-(void)_captureCurrentView{
    @synchronized (self) {
        
        UIGraphicsBeginImageContext(self.captureSize);
        UIImage *image;
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        if (!_mixtureRecorder) {
            [self.captureView.layer renderInContext:ctx];
            image = UIGraphicsGetImageFromCurrentImageContext();
        }else{
            for (int i = 0; i< _mixtureCaptureBelowView.count; i++) {
                [_mixtureCaptureBelowView[i].layer renderInContext:ctx];
            }
            UIImage* glImage = [ImageTool glToUIImageWithRect:CGRectMake(0, 0, _glRect.size.width, _glRect.size.height)];
            [glImage drawInRect:_glRect];
            for (int i = 0; i< _mixtureCaptureAboveView.count; i++) {
                [_mixtureCaptureAboveView[i].layer renderInContext:ctx];
            }
            image = UIGraphicsGetImageFromCurrentImageContext();
        }
  
        if (image) {
            switch (self.recorderType) {
                case screenRecorderFileType:
//                    [_cacheArry addObject:image];
                    [_imageCache queuePush:image limit:INT_MAX];
                    break;
                case screenRecorderRealImageType:
                    if ([self.delegate respondsToSelector:@selector(ScreenRecorder:recorderImage:FinishWithError:)]) {
                            [self.delegate ScreenRecorder:self recorderImage:image FinishWithError:nil];
                    }
                    break;
                case screenRecorderRealRGBA8Type:
                {
                    NSData* data = [ImageTool convertUIImageToBitmapRGBA8:image];
                    if ([self.delegate respondsToSelector:@selector(ScreenRecorder:recorderRGBA8Data:FinishWithError:)]) {
                        [self.delegate ScreenRecorder:self recorderRGBA8Data:data FinishWithError:nil];
                    }
                }
                    break;
                case screenRecorderRealYUVType:
                {
                    NSData* data = [ImageTool convertUIImageToBitmapYUV240P:image];
                    if ([self.delegate respondsToSelector:@selector(ScreenRecorder:recorderYUVData:FinishWithError:)]) {
                        [self.delegate ScreenRecorder:self recorderYUVData:data FinishWithError:nil];
                    }
                }
                    break;
                case screenRecorderRealH264Type:
                {
                    if (_h264Encoder == nil) {
                        _h264Encoder = [[GJH264Encoder alloc]initWithFps:(uint)_fps];
                        _h264Encoder.deleagte = self;
                    }
                    CVImageBufferRef imgRef = [self pixelBufferFromCGImage:[image CGImage] size:image.size];
                
                    [_h264Encoder encodeImageBuffer:imgRef fourceKey:NO];
                
                }
                    break;
                default:
                    break;
            }
            _totalCount++;
        }
        UIGraphicsEndImageContext();
    }
}

-(UIImage*)captureImageWithView:(UIView*)view{
    UIImage *image ;
    @synchronized (self) {
        UIGraphicsBeginImageContext(view.bounds.size);
        [view.layer renderInContext:UIGraphicsGetCurrentContext()];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return image;
}

-(UIImage*)captureGLMixtureWithGLRect:(CGRect)glRect AboveView:(NSArray<UIView*>*)aboveView
                        aboveRect:(NSArray<NSValue*>*)aboveRect
                        belowView:(NSArray<UIView*>*)belowView
                        belowRect:(NSArray<NSValue*>*)belowRect
                         hostSize:(CGSize)hostSize{
    UIImage *image ;
    @synchronized (self) {
        UIGraphicsBeginImageContext(hostSize);
        CGContextRef ctx = UIGraphicsGetCurrentContext();

        for (int i = 0; i< belowView.count; i++) {
            CGRect rect = [belowRect[i] CGRectValue];
            CGContextTranslateCTM(ctx, rect.origin.x, rect.origin.y);
            [belowView[i].layer renderInContext:ctx];
            CGContextTranslateCTM(ctx, -rect.origin.x, -rect.origin.y);
        }
        UIImage* glImage = [ImageTool glToUIImageWithRect:CGRectMake(0, 0, glRect.size.width, glRect.size.height)];
        [glImage drawInRect:glRect];
        for (int i = 0; i< aboveView.count; i++) {
            CGRect rect = [aboveRect[i] CGRectValue];
            CGContextTranslateCTM(ctx, rect.origin.x, rect.origin.y);
            [aboveView[i].layer renderInContext:ctx];
            CGContextTranslateCTM(ctx, -rect.origin.x, -rect.origin.y);
        }
        image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }
    return image;
}

-(void)startGLMixtureWithGLRect:(CGRect)glRect AboveView:(NSArray<UIView*>*)aboveView
                      aboveRect:(NSArray<NSValue*>*)aboveRect
                      belowView:(NSArray<UIView*>*)belowView
                      belowRect:(NSArray<NSValue*>*)belowRect
                       hostSize:(CGSize)hostSize
                            fps:(NSInteger)fps
                        fileUrl:(NSString*)fileUrl{
    _mixtureRecorder = YES;
    _mixtureCaptureAboveView = aboveView;
    _mixtureCaptureBelowView = belowView;
    _glRect = glRect;
    _captureSize = hostSize;
    [self _startWithFps:fps fileUrl:fileUrl];
}
-(void)startWithView:(UIView*)targetView fps:(NSInteger)fps fileUrl:(NSString*)fileUrl{
    _mixtureRecorder = NO;
    _captureView=targetView;
    _captureSize = targetView.bounds.size;
    [self _startWithFps:fps fileUrl:fileUrl];
}
-(void)_startWithFps:(NSInteger)fps fileUrl:(NSString*)fileUrl{
    _status = screenRecorderRecorderingStatus;
    _fps = fps;
    _destFileUrl = fileUrl;
    if(_pixelBuffer){
        CFRelease(_pixelBuffer);
        _pixelBuffer=NULL;
    }
    
    if (_recorderType == screenRecorderFileType || _recorderType == screenRecorderRealH264Type){
        //cache buffer
        CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, _captureSize.width, _captureSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) _options, &_pixelBuffer);
        NSParameterAssert(status == kCVReturnSuccess && _pixelBuffer != NULL);
        if(_recorderType == screenRecorderFileType){
            //start
            [self _writeFile];
        }
    }
    __weak ScreenRecorder* wkSelf = self;
    dispatch_async(_captureQueue, ^{
        wkSelf.fpsTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/fps target:self selector:@selector(_captureCurrentView) userInfo:nil repeats:YES];
        [wkSelf.fpsTimer fire];
        _captureRunLoop = CFRunLoopGetCurrent();
        
        //        NSDate* date = [NSDate distantFuture];
        CFRunLoopRunInMode(kCFRunLoopDefaultMode,DBL_MAX, NO);
        NSLog(@"after runloop:%d",_recorderType);
    });
    
}
-(void)stopRecord{
    if (_captureRunLoop) {
        CFRunLoopStop(_captureRunLoop);
        _captureRunLoop = NULL;
    }
    [_fpsTimer invalidate];
    _fpsTimer=nil;
    _status = screenRecorderStopStatus;
    NSLog(@"recode stop");
}
-(void)pause{
    _status = screenRecorderPauseStatus;
    [_fpsTimer setFireDate:[NSDate distantFuture]];
}
-(void)resume{
    _status = screenRecorderRecorderingStatus;
    [_fpsTimer setFireDate:[NSDate date]];
}

-(void)_writeFile{
    
    if([[NSFileManager defaultManager] fileExistsAtPath:self.destFileUrl])
    {
        //remove the old one
        [[NSFileManager defaultManager] removeItemAtPath:self.destFileUrl error:nil];
    }
    
    
    CGSize size = _captureSize;
    NSError *error = nil;
    
    unlink([_destFileUrl UTF8String]);
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:_destFileUrl]
                                                           fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    NSParameterAssert(videoWriter);
    if(error)NSLog(@"error = %@", [error localizedDescription]);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey, nil];
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    NSParameterAssert(writerInput);
    
    if (![videoWriter canAddInput:writerInput]){
        NSLog(@"can not AddInput error,");
        return;
    }
    
    [videoWriter addInput:writerInput];
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    dispatch_queue_t dispatchQueue = dispatch_queue_create("ScreenRecorderWriteQueue", NULL);
    
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    [writerInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
        while ([writerInput isReadyForMoreMediaData])
        {
            if(_status == screenRecorderStopStatus)
            {
                //clean cache
                [_imageCache clean];
                [writerInput markAsFinished];
                [videoWriter finishWritingWithCompletionHandler:^{
                    if ([self.delegate respondsToSelector:@selector(ScreenRecorder:recorderFile:FinishWithError:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate ScreenRecorder:self recorderFile:self.destFileUrl FinishWithError:nil];
                        });
                    }
                }];
                break;
            }else{
                UIImage* image ;
                if ([_imageCache queuePop:&image limit:0.2]) {
                    CVPixelBufferRef buffer = [self pixelBufferFromCGImage:[image CGImage] size:size];
                    CFAbsoluteTime interval = (CFAbsoluteTimeGetCurrent() - startTime) * 1000;
                    CMTime currentSampleTime = CMTimeMake((int)interval, 1000);
                    if(![adaptor appendPixelBuffer:buffer withPresentationTime:currentSampleTime])
                        NSLog(@"appendPixelBuffer error");
                }                
            }
        }
    }];
}
-(CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size
{
    CVPixelBufferLockBaseAddress(_pixelBuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(_pixelBuffer);
    NSParameterAssert(pxdata != NULL);
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width, size.height, 8, 4*size.width, rgbColorSpace, kCGImageAlphaPremultipliedFirst);
    NSParameterAssert(context);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(_pixelBuffer, 0);
    return _pixelBuffer;
}


-(void)GJH264Encoder:(GJH264Encoder *)encoder encodeCompleteBuffer:(uint8_t *)buffer withLenth:(long)totalLenth keyFrame:(BOOL)keyFrame dts:(int64_t)dts{
    if ([self.delegate respondsToSelector:@selector(ScreenRecorder:recorderH264Data:withLenth:keyFrame:dts:)]) {
        [self.delegate ScreenRecorder:self recorderH264Data:buffer withLenth:totalLenth keyFrame:keyFrame dts:dts];
    }
}
-(void)dealloc{
    NSLog(@"screenrecorder delloc:%@",self);
}
@end
