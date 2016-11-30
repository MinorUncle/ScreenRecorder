//
//  ScreenRecorder.m
//  ScreenRecorderDemo
//
//  Created by mac on 16/11/17.
//  Copyright © 2016年 zhouguangjin. All rights reserved.
//

#import "ScreenRecorder.h"
#import "GJQueue.h"
#import <AVFoundation/AVFoundation.h>
#import <OpenGLES/ES2/gl.h>
#import "ImageTool.h"
#import <ReplayKit/ReplayKit.h>



@interface RPPreviewViewController()
@property(nonatomic,strong)NSURL*movieURL;
@end

@interface ScreenRecorder()<GJH264EncoderDelegate,RPScreenRecorderDelegate>
{
    GJQueue* _imageCache;//缓冲
    dispatch_queue_t _writeQueue;
    NSDictionary* _options;//cache
    CVPixelBufferRef _pixelBuffer ;//cache
    NSInteger* _totalCount;
    CFRunLoopRef _captureRunLoop;
}
@property(strong,nonatomic)NSTimer* fpsTimer;

@end

@implementation ScreenRecorder
- (instancetype)init
{
    return [self initWithType:screenRecorderRealYUVType];
}
- (instancetype)initWithType:(ScreenRecorderType)recorderType
{
    self = [super init];
    if (self) {
        _captureQueue = dispatch_queue_create("captureQueue", DISPATCH_QUEUE_CONCURRENT);
        _recorderType = recorderType;
        _imageCache = [[GJQueue alloc]init];
        _imageCache.autoResize = false;
        _options = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                    [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
        
    }
    return self;
}

#pragma mark interface

-(UIImage*)captureImageWithView:(UIView*)view{
    UIImage *image ;
    UIGraphicsBeginImageContext(view.bounds.size);
    [view drawViewHierarchyInRect:self.captureView.frame afterScreenUpdates:NO];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
-(void)startWithView:(UIView*)targetView fps:(NSInteger)fps{
    _captureView=targetView;
    _captureFrame = [self _getRootFrameWithView:targetView];
    _status = screenRecorderRecorderingStatus;
    _fps = fps;
    
    if(_pixelBuffer){
        CFRelease(_pixelBuffer);
        _pixelBuffer=NULL;
    }
    if (_recorderType == screenRecorderFileType || _recorderType == screenRecorderRealH264Type){
        //cache buffer
        CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, _captureFrame.size.width, _captureFrame.size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) _options, &_pixelBuffer);
        if (status != kCVReturnSuccess) {
            return;
        }
        if(_recorderType == screenRecorderFileType){
            //start
            [self _writeFile];
        }
    }
    __weak ScreenRecorder* wkSelf = self;
    if(fps>0){
        dispatch_async(_captureQueue, ^{
            wkSelf.fpsTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/fps target:self selector:@selector(_captureCurrentView) userInfo:nil repeats:YES];
            [wkSelf.fpsTimer fire];
            _captureRunLoop = CFRunLoopGetCurrent();
            CFRunLoopRunInMode(kCFRunLoopDefaultMode,DBL_MAX, NO);
            RecorderLOG(@"after runloop:%d",_recorderType);
        });
    }

}
-(BOOL)canCaptureFullScreenFileFast{
    return USE_REPLAYKIT && [[UIDevice currentDevice].systemVersion doubleValue] >= 9.0;
}
-(void)startCaptureFullScreenFileFast{
    if ([self canCaptureFullScreenFileFast]) {
        _status = screenRecorderRecorderingStatus;
        [RPScreenRecorder sharedRecorder].delegate = self;
        __weak ScreenRecorder* wkSelf = self;
        
        [[RPScreenRecorder sharedRecorder] startRecordingWithMicrophoneEnabled:NO handler:^(NSError * _Nullable error) {
            if (error) {
                _status = screenRecorderStopStatus;
                
                if ([wkSelf.delegate respondsToSelector:@selector(screenRecorder:recorderFile:FinishWithError:)]) {
                    [wkSelf.delegate screenRecorder:wkSelf recorderFile:nil FinishWithError:error];
                }
            }
        }];
    }
}


-(void)stopRecord{
    _status = screenRecorderStopStatus;

    if (_captureRunLoop) {
        CFRunLoopStop(_captureRunLoop);
        _captureRunLoop = NULL;
    }
    if (_fpsTimer) {
        [_fpsTimer invalidate];
        _fpsTimer=nil;
    }
    
    if ([RPScreenRecorder sharedRecorder].isRecording) {
        __weak ScreenRecorder* wkSelf = self;
        [[RPScreenRecorder sharedRecorder] stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
            if (!error) {
                NSError* copyError = nil;
                [[NSFileManager defaultManager]copyItemAtURL:previewViewController.movieURL toURL:wkSelf.destFileUrl error:&copyError];
                error = copyError;
            }
            if ([self.delegate respondsToSelector:@selector(screenRecorder:recorderFile:FinishWithError:)]) {
                [self.delegate screenRecorder:wkSelf recorderFile:previewViewController.movieURL FinishWithError:error];
            }
        }];
    }
}
-(void)pause{
    _status = screenRecorderPauseStatus;
    [_fpsTimer setFireDate:[NSDate distantFuture]];
}
-(void)resume{
    _status = screenRecorderRecorderingStatus;
    [_fpsTimer setFireDate:[NSDate date]];
}



#pragma mark internal

-(void)_captureCurrentView{
        UIGraphicsBeginImageContextWithOptions(self.captureFrame.size, YES, 1.0);
        [self.captureView drawViewHierarchyInRect:self.captureFrame afterScreenUpdates:NO];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        if (image) {
            switch (self.recorderType) {
                case screenRecorderFileType:
                    [_imageCache queuePush:image limit:INT_MAX];
                    break;
                case screenRecorderRealImageType:
                    if ([self.delegate respondsToSelector:@selector(screenRecorder:recorderImage:FinishWithError:)]) {
                        [self.delegate screenRecorder:self recorderImage:image FinishWithError:nil];
                    }
                    break;
                case screenRecorderRealRGBA8Type:
                {
                    NSData* data = [ImageTool convertUIImageToBitmapRGBA8:image];
                    if ([self.delegate respondsToSelector:@selector(screenRecorder:recorderRGBA8Data:FinishWithError:)]) {
                        [self.delegate screenRecorder:self recorderRGBA8Data:data FinishWithError:nil];
                    }
                }
                    break;
                case screenRecorderRealYUVType:
                {
                    NSData* data = [ImageTool convertUIImageToBitmapYUV240P:image];
                    if ([self.delegate respondsToSelector:@selector(screenRecorder:recorderYUVData:FinishWithError:)]) {
                        [self.delegate screenRecorder:self recorderYUVData:data FinishWithError:nil];
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
}

-(CGRect)_getRootFrameWithView:(UIView*)view{
    CGRect rect = view.frame;
    UIView* superView = view.superview;
    while (superView) {
        rect.origin.x += superView.frame.origin.x;
        rect.origin.y += superView.frame.origin.y;
        superView = superView.superview;
    }
    return rect;
}


-(NSURL *)destFileUrl{
    if (_destFileUrl == nil) {
        NSDateFormatter* format = [[NSDateFormatter alloc]init];
        [format setDateFormat:@"yyyy_MM_dd_HH_mm_ss"];
        NSString* path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
        path = [path stringByAppendingPathComponent:@"RecoderFile"];
        if (![[NSFileManager defaultManager]fileExistsAtPath:path]) {
            [[NSFileManager defaultManager]createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSString* file = [format stringFromDate:[NSDate date]];
        path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",file]];
        _destFileUrl = [NSURL fileURLWithPath:path];
    }
    return _destFileUrl;
}


-(void)_writeFile{
    
    if([[NSFileManager defaultManager] fileExistsAtPath:self.destFileUrl.path])
    {
        //remove the old one
        [[NSFileManager defaultManager] removeItemAtPath:self.destFileUrl.path error:nil];
    }
    
    CGSize size = _captureFrame.size;
    NSError *error = nil;
    
    unlink([self.destFileUrl path].UTF8String);
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:self.destFileUrl.path]
                                                           fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    NSParameterAssert(videoWriter);
    if(error)RecorderLOG(@"error = %@", [error localizedDescription]);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey, nil];
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    NSParameterAssert(writerInput);
    
    if (![videoWriter canAddInput:writerInput]){
        RecorderLOG(@"can not AddInput error,");
        return;
    }
    
    [videoWriter addInput:writerInput];
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    dispatch_queue_t dispatchQueue = dispatch_queue_create("ScreenRecorderWriteQueue", DISPATCH_QUEUE_SERIAL);
    
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    [writerInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
        static int queueCount = 0;
        RecorderLOG(@"requestMediaDataWhenReadyOnQueue:%d",queueCount++);
        while ([writerInput isReadyForMoreMediaData])
        {
            static int ReadyCount = 0;
            RecorderLOG(@"isReadyForMoreMediaData:%d",ReadyCount++);
            if(_status == screenRecorderStopStatus)
            {
                RecorderLOG(@"markAsFinished");
                //clean cache
                [_imageCache clean];
                [writerInput markAsFinished];
                [videoWriter finishWritingWithCompletionHandler:^{
                    if ([self.delegate respondsToSelector:@selector(screenRecorder:recorderFile:FinishWithError:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate screenRecorder:self recorderFile:self.destFileUrl FinishWithError:nil];
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
                    if(![adaptor appendPixelBuffer:buffer withPresentationTime:currentSampleTime]){
                        RecorderLOG(@"appendPixelBuffer error");
                    }else{
                        RecorderLOG(@"appendPixelBuffer time:%f",interval);
                    }
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


#pragma mark delegate

-(void)GJH264Encoder:(GJH264Encoder *)encoder encodeCompleteBuffer:(uint8_t *)buffer withLenth:(long)totalLenth keyFrame:(BOOL)keyFrame dts:(int64_t)dts{
    if ([self.delegate respondsToSelector:@selector(screenRecorder:recorderH264Data:withLenth:keyFrame:dts:)]) {
        [self.delegate screenRecorder:self recorderH264Data:buffer withLenth:totalLenth keyFrame:keyFrame dts:dts];
    }
}
-(void)dealloc{
    if(_pixelBuffer){
        CFRelease(_pixelBuffer);
        _pixelBuffer=NULL;
    }
    RecorderLOG(@"screenrecorder delloc:%@",self);
}
@end
