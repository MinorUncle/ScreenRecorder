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


@property(assign,nonatomic,readonly)CGSize captureSize;
@property(strong,nonatomic,readonly)UIView* captureView;


@property(strong,nonatomic,readonly)NSArray<UIView*>* mixtureCaptureAboveView;
@property(strong,nonatomic,readonly)NSArray<NSValue*>* mixtureCaptureAboveViewFrame;
@property(strong,nonatomic,readonly)NSArray<UIView*>* mixtureCaptureBelowView;
@property(strong,nonatomic,readonly)NSArray<NSValue*>* mixtureCaptureBelowViewFrame;


@property(strong,nonatomic)dispatch_queue_t captureQueue;///mast same with rander queue_t.,assign before start.DISPATCH_QUEUE_CONCURRENT type
@property(strong,nonatomic,readonly)id syncToken;//当使用同步截屏的时候，必须在opengl渲染代码上用此token配合@synchronized加同步锁。
@property(nonatomic,copy)NSURL* destFileUrl;
@property(nonatomic,weak)id<ScreenRecorderDelegate> delegate;

- (instancetype)initWithType:(ScreenRecorderType)recorderType;
//普通截屏，fileUrl可为空，
-(void)startWithView:(UIView*)targetView fps:(NSInteger)fps;

/**
 GL混合截图需要截三部分，gl视图下面视图，gl视图，gl上面视图，然后混合
 
 异步截屏
 渲染代码必须用syncToken加同步锁，否则可能崩溃,截屏效果差,容易截到黑屏。
 自动控制fps,
 @param glRect 需要截图的gl 视图的frame
 @param aboveView gl视图上层视图（尽量只放最底层一张，有父视图就不需要子视图）
 @param aboveRect gl视图上层视图frame
 @param belowView gl下层视图
 @param belowRect 下层视图frame
 @param hostSize 最终image大小
 @param fps 帧率
 */
-(void)startGLMixtureWithGLRect:(CGRect)glRect
                      AboveView:(NSArray<UIView*>*)aboveView
                      aboveRect:(NSArray<NSValue*>*)aboveRect
                      belowView:(NSArray<UIView*>*)belowView
                      belowRect:(NSArray<NSValue*>*)belowRect
                       hostSize:(CGSize)hostSize//帧大小
                            fps:(NSInteger)fps;



/**
 同步截屏
通过serialCaptureWithGLBuffer提供gl数据，可自己控制每一帧时间
 @param glRect <#glRect description#>
 @param aboveView <#aboveView description#>
 @param aboveRect <#aboveRect description#>
 @param belowView <#belowView description#>
 @param belowRect <#belowRect description#>
 @param hostSize <#hostSize description#>
 */
-(void)startSerialGLMixtureWithGLRect:(CGRect)glRect AboveView:(NSArray<UIView*>*)aboveView
                            aboveRect:(NSArray<NSValue*>*)aboveRect
                            belowView:(NSArray<UIView*>*)belowView
                            belowRect:(NSArray<NSValue*>*)belowRect
                             hostSize:(CGSize)hostSize;

/**
 gl层视图数据数据
 请OPGL渲染一帧后线程同步调用，
 @param image gl层数据
 */
-(void)serialCaptureWithGLBuffer:(UIImage*)image;


/**
 replaykit截屏，只能全屏保存为视频，视频暂时只能用来播放，
 */
-(BOOL)canCaptureFullScreenFileFast;
-(void)startCaptureFullScreenFileFast;


-(void)stopRecord;
-(void)pause;
-(void)resume;

/**
 gl截图片
 */
-(UIImage*)captureGLMixtureWithGLRect:(CGRect)glRect
                            AboveView:(NSArray<UIView*>*)aboveView
                            aboveRect:(NSArray<NSValue*>*)aboveRect
                            belowView:(NSArray<UIView*>*)belowView
                            belowRect:(NSArray<NSValue*>*)belowRect
                             hostSize:(CGSize)hostSize;

-(UIImage*)captureImageWithView:(UIView*)view;


@end
