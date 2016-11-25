//
//  ScreenRecorder.h
//  ScreenRecorderDemo
//
//  Created by mac on 16/11/17.
//  Copyright © 2016年 lezhixing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIView.h>
#import "GJH264Encoder.h"

#define USE_REPLAYKIT 1

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
@property(readonly,nonatomic,copy)NSURL* destFileUrl;
@property(nonatomic,weak)id<ScreenRecorderDelegate> delegate;

@property(assign,nonatomic,readonly)CGSize captureSize;
@property(weak,nonatomic,readonly)UIView* captureView;
@property(strong,nonatomic,readonly)id syncToken;//暂时没用


@property(strong,nonatomic,readonly)NSArray<UIView*>* mixtureCaptureAboveView;
@property(strong,nonatomic,readonly)NSArray<NSValue*>* mixtureCaptureAboveViewFrame;
@property(strong,nonatomic,readonly)NSArray<UIView*>* mixtureCaptureBelowView;
@property(strong,nonatomic,readonly)NSArray<NSValue*>* mixtureCaptureBelowViewFrame;


@property(strong,nonatomic)dispatch_queue_t captureQueue;///mast same with rander queue_t.,assign before start


- (instancetype)initWithType:(ScreenRecorderType)recorderType;
-(void)startWithView:(UIView*)targetView fps:(NSInteger)fps fileUrl:(NSURL*)fileUrl;

//可能崩溃,截屏效果差,容易黑屏
-(void)startGLMixtureWithGLRect:(CGRect)glRect AboveView:(NSArray<UIView*>*)aboveView
                      aboveRect:(NSArray<NSValue*>*)aboveRect
                      belowView:(NSArray<UIView*>*)belowView
                      belowRect:(NSArray<NSValue*>*)belowRect
                       hostSize:(CGSize)hostSize
                            fps:(NSInteger)fps
                        fileUrl:(NSURL*)fileUrl;


//请OPGL渲染一帧后调用，同步截屏
-(void)startSerialGLMixtureWithGLRect:(CGRect)glRect AboveView:(NSArray<UIView*>*)aboveView
                            aboveRect:(NSArray<NSValue*>*)aboveRect
                            belowView:(NSArray<UIView*>*)belowView
                            belowRect:(NSArray<NSValue*>*)belowRect
                             hostSize:(CGSize)hostSize
                              fileUrl:(NSURL*)fileUrl;
-(void)serialCaptureWithGLBuffer:(UIImage*)data;//gl层视图数据数据

-(BOOL)canCaptureFullScreenFileFast;
-(void)startCaptureFullScreenFileFast;


-(void)stopRecord;
-(void)pause;
-(void)resume;

-(UIImage*)captureGLMixtureWithGLRect:(CGRect)glRect//gl层的frame，相对hostSize gl视图宽高一定要偶数数;
                            AboveView:(NSArray<UIView*>*)aboveView//gl层上面视图,数组尽量少，最好是一个
                            aboveRect:(NSArray<NSValue*>*)aboveRect//gl层上面视图frame
                            belowView:(NSArray<UIView*>*)belowView//gl层下层视图,数组尽量少，最好是一个
                            belowRect:(NSArray<NSValue*>*)belowRect//gl层下层视图
                             hostSize:(CGSize)hostSize;//图片大小
-(UIImage*)captureImageWithView:(UIView*)view;


@end
