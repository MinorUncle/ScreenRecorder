//
//  ScreenRecorder.h
//  ScreenRecorderDemo
//
//  Created by mac on 16/11/17.
//  Copyright © 2016年 zhouguangjin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIView.h>
#import "GJH264Encoder.h"

#define USE_REPLAYKIT 1
#ifdef DEBUG
#define RecorderLOG(format, ...) NSLog(format,##__VA_ARGS__)
#else
#define RecorderLOG(format, ...)
#endif

@class ScreenRecorder;
@protocol ScreenRecorderDelegate <NSObject>
@optional
-(void)screenRecorder:(ScreenRecorder*)recorder recorderFile:(NSURL*)fileUrl FinishWithError:(NSError*) error;
-(void)screenRecorder:(ScreenRecorder*)recorder recorderImage:(UIImage*)image FinishWithError:(NSError*) error;
-(void)screenRecorder:(ScreenRecorder*)recorder recorderYUVData:(NSData*)yuvData FinishWithError:(NSError*) error;
-(void)screenRecorder:(ScreenRecorder*)recorder recorderRGBA8Data:(NSData*)RGBA8Data FinishWithError:(NSError*) error;
-(void)screenRecorder:(ScreenRecorder*)recorder recorderH264Data:(uint8_t *)buffer withLenth:(long)totalLenth keyFrame:(BOOL)keyFrame dts:(int64_t)dts;

@end

typedef enum ScreenRecorderType{
    screenRecorderRealYUVType,
    screenRecorderRealRGBA8Type,
    screenRecorderRealImageType,
    screenRecorderRealH264Type,
    screenRecorderFileType
}ScreenRecorderType;
typedef enum ScreenRecorderStatus{
    screenRecorderStopStatus,
    screenRecorderPauseStatus,
    screenRecorderRecorderingStatus,
}ScreenRecorderStatus;
@interface ScreenRecorder : NSObject
@property(readonly,nonatomic,assign)ScreenRecorderType recorderType;
@property(readonly,nonatomic,retain)GJH264Encoder* h264Encoder;
@property(readonly,nonatomic,assign)NSInteger fps;
@property(readonly,nonatomic,assign)ScreenRecorderStatus status;

@property(assign,nonatomic,readonly)CGRect captureFrame;
@property(strong,nonatomic,readonly)UIView* captureView;
@property(strong,nonatomic)dispatch_queue_t captureQueue;
@property(nonatomic,copy)NSURL* destFileUrl;
@property(nonatomic,weak)id<ScreenRecorderDelegate> delegate;

- (instancetype)initWithType:(ScreenRecorderType)recorderType;

-(void)startWithView:(UIView*)targetView fps:(NSInteger)fps;

/**
 replaykit截屏，只能全屏保存为视频，视频暂时只能用来播放，
 */
-(BOOL)canCaptureFullScreenFileFast;
-(void)startCaptureFullScreenFileFast;


-(void)stopRecord;
-(void)pause;
-(void)resume;
-(void)addExternalAudioSource:(uint8_t*)data size:(int)size pts:(double)pts;
-(UIImage*)captureImageWithView:(UIView*)view;


@end
