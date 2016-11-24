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
@class ScreenRecorder;
@protocol ScreenRecorderDelegate <NSObject>
@optional
-(void)ScreenRecorder:(ScreenRecorder*)recorder recorderFile:(NSString*)fileUrl FinishWithError:(NSError*) error;
-(void)ScreenRecorder:(ScreenRecorder*)recorder recorderImage:(UIImage*)image FinishWithError:(NSError*) error;
-(void)ScreenRecorder:(ScreenRecorder*)recorder recorderYUVData:(NSData*)yuvData FinishWithError:(NSError*) error;
-(void)ScreenRecorder:(ScreenRecorder*)recorder recorderRGBA8Data:(NSData*)RGBA8Data FinishWithError:(NSError*) error;
-(void)ScreenRecorder:(ScreenRecorder*)recorder recorderH264Data:(uint8_t *)buffer withLenth:(long)totalLenth keyFrame:(BOOL)keyFrame dts:(int64_t)dts;


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
@property(readonly,nonatomic,copy)NSString* destFileUrl;
@property(nonatomic,weak)id<ScreenRecorderDelegate> delegate;

@property(assign,nonatomic,readonly)CGSize captureSize;
@property(weak,nonatomic,readonly)UIView* captureView;

@property(strong,nonatomic,readonly)NSArray<UIView*>* mixtureCaptureAboveView;
@property(strong,nonatomic,readonly)NSArray<NSValue*>* mixtureCaptureAboveViewFrame;
@property(strong,nonatomic,readonly)NSArray<UIView*>* mixtureCaptureBelowView;
@property(strong,nonatomic,readonly)NSArray<NSValue*>* mixtureCaptureBelowViewFrame;


@property(strong,nonatomic)dispatch_queue_t captureQueue;///mast same with rander queue_t.,assign before start


- (instancetype)initWithType:(ScreenRecorderType)recorderType;
-(void)startWithView:(UIView*)targetView fps:(NSInteger)fps fileUrl:(NSString*)fileUrl;

-(void)startGLMixtureWithGLRect:(CGRect)glRect AboveView:(NSArray<UIView*>*)aboveView
                      aboveRect:(NSArray<NSValue*>*)aboveRect
                      belowView:(NSArray<UIView*>*)belowView
                      belowRect:(NSArray<NSValue*>*)belowRect
                       hostSize:(CGSize)hostSize
                            fps:(NSInteger)fps
                        fileUrl:(NSString*)fileUrl;

-(void)stopRecord;
-(void)pause;
-(void)resume;
-(UIImage*)captureImageWithView:(UIView*)view;


-(UIImage*)captureGLMixtureWithGLRect:(CGRect)glRect AboveView:(NSArray<UIView*>*)aboveView
                      aboveRect:(NSArray<NSValue*>*)aboveRect
                      belowView:(NSArray<UIView*>*)belowView
                      belowRect:(NSArray<NSValue*>*)belowRect
                       hostSize:(CGSize)hostSize;

@end
