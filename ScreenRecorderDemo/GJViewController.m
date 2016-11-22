//
//  GJViewController.m
//  Demo
//
//  Created by 白冰 on 13-7-25.
//  Copyright (c) 2013年 . All rights reserved.
//

#import "GJViewController.h"
#import "FilePlayerView.h"
#import "OpenGLView20.h"
//#import "DrawView.h"
#import "DrawBoard.h"
#import "ImageTool.h"
#import <AVFoundation/AVPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVPlayerLayer.h>
#import <MediaPlayer/MediaPlayer.h>
#import "ScreenRecorder.h"
#import "GJPullDownView.h"

#import "GJH264Decoder.h"
#define MainFrame [[UIScreen mainScreen] applicationFrame]
#define MainFrameLandscape CGRectMake(0.0f, 0.0f, MainFrame.size.height, MainFrame.size.width)
#define DOCSFOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/"]
#define VideoPath [DOCSFOLDER stringByAppendingPathComponent:@"test.mp4"]


@interface GJViewController ()<ScreenRecorderDelegate,GJPullDownViewDelegate,GJH264DecoderDelegate>
{
    DrawBoard *_drawView;
    ScreenRecorder *myScreenRecorder;
    FilePlayerView *_movieShow;
    UIButton* _drawButton;
    UIButton* _glCaptureButton;

    GJPullDownView* _produceType;
    GJPullDownView* _displayType;
    UIView* _produceView;
    UIView* _displayView;
    
    UIImageView* _imageShowView;
    OpenGLView20* _yuvShowView;
    
    GJH264Decoder* _h264Decoder;
    NSString* _fileUrl;
    
    
    UIImageView* _iconShow;
    
}
@property(nonatomic,strong)AVPlayer* player;

-(void)readyInit;

@end

@implementation GJViewController
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
//    [_movieShow setFileURL:[NSURL URLWithString:_fileUrl]];
//    [_movieShow playWithFinish:^(BOOL finished) {
//        NSLog(@"play success");
//    }];
//    return;
    [myScreenRecorder startWithView:_drawView fps:15 fileUrl:_fileUrl];
    _drawButton.selected = YES;
}

-(void)drawClick:(UIButton*)button
{
    button.selected = !button.selected;
    if (button.selected) {
        if (_displayType.currentTag == screenRecorderFileType) {
            [myScreenRecorder startWithView:_drawView fps:15 fileUrl:VideoPath];
        }else{
            [myScreenRecorder resume];
        }
    }else{
        if (_displayType.currentTag == screenRecorderFileType) {
            [myScreenRecorder stopRecord];
        }else{
            [myScreenRecorder pause];
        }
    }
}

-(void)readyInit
{
    
    NSString* path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    _fileUrl = [path stringByAppendingPathComponent:@"test.mp4"];
//    _fileUrl = [[NSBundle mainBundle]pathForResource:@"2016031903" ofType:@"mp4"];
    
    CGFloat midH = 20.0,midW = 50.0,padding = 5.0;
    int itemCount = 4;
    CGFloat margin = (self.view.bounds.size.width - 2*padding -itemCount*midW)/(itemCount-1);
    myScreenRecorder = [[ScreenRecorder alloc] initWithType:screenRecorderFileType];
    myScreenRecorder.delegate = self;
    
    self.view.backgroundColor = [UIColor whiteColor];
    CGRect rect = self.view.bounds;
    rect.size.height = (rect.size.height-midH)*0.5;
    
    _produceView = [[UIView alloc]initWithFrame:rect];
    _produceView.backgroundColor = [UIColor whiteColor];
    
    rect.origin.y=CGRectGetMaxY(rect)+1;
    rect.size.height = midH;
    rect.origin.x=padding;
    rect.size.width = midW;
    _produceType = [[GJPullDownView alloc]initWithItems:@[@"手绘",@"视频"]];
    _produceType.frame = rect;
    [_produceView addSubview:_produceType];
    _produceType.PullDownViewDelegate = self;
    _produceType.backgroundColor = [UIColor whiteColor];
    rect.origin.x = CGRectGetMaxX(rect) + margin;
    _drawButton = [[UIButton alloc]initWithFrame:rect];
    [_drawButton addTarget:self action:@selector(drawClick:) forControlEvents:UIControlEventTouchUpInside];
    [_drawButton setTitle:@"继续" forState:UIControlStateNormal];
    [_drawButton setTitle:@"暂停" forState:UIControlStateSelected];
    [_drawButton setBackgroundColor:[UIColor grayColor]];
   
    
    rect.origin.x = CGRectGetMaxX(rect) + margin;
    _displayType = [[GJPullDownView alloc]initWithItems:@[@"YUVType",@"RGBA8Type",@"ImageType",@"H264Type",@"FileType"]];
    _displayType.itemTags=@[@(screenRecorderRealYUVType),@(screenRecorderRealRGBA8Type),@(screenRecorderRealImageType),@(screenRecorderRealH264Type),@(screenRecorderFileType)];
    _displayType.currentTag = myScreenRecorder.recorderType;
    _displayType.frame = rect;
    _displayType.listTextFont = [UIFont systemFontOfSize:8.0];
    _displayType.sectionLable.font = [UIFont systemFontOfSize:8.0];

    _displayType.PullDownViewDelegate = self;
    
    rect.origin.x = CGRectGetMaxX(rect) + margin;
    _glCaptureButton = [[UIButton alloc]initWithFrame:rect];
    [_glCaptureButton addTarget:self action:@selector(glCapture) forControlEvents:UIControlEventTouchUpInside];
    [_glCaptureButton setTitle:@"GL截图" forState:UIControlStateNormal];
    [_glCaptureButton setBackgroundColor:[UIColor grayColor]];
    

    rect.origin.y=CGRectGetMaxY(rect)+1;
    rect.size = _produceView.bounds.size;
    rect.origin.x=0;
    _displayView = [[UIView alloc]initWithFrame:rect];
    _displayView.backgroundColor = [UIColor whiteColor];
    _imageShowView = [[UIImageView alloc]initWithFrame:_displayView.bounds];
    _movieShow = [[FilePlayerView alloc]init];
    _movieShow.frame = _displayView.bounds;
    _yuvShowView = [[OpenGLView20 alloc]initWithFrame:_displayView.bounds];
    [_displayView addSubview:_movieShow];
    
    _drawView = [[DrawBoard alloc] initWithFrame:_produceView.bounds];
//    _drawView.image = [UIImage imageNamed:@"13031I1XF-14H6"];
    _drawView.backgroundColor = [UIColor redColor];
    _drawView.userInteractionEnabled = YES;
    [_produceView addSubview:_drawView];

    rect = CGRectMake(0, 0, 100, 80);
    _iconShow = [[UIImageView alloc]initWithFrame:rect];
    _iconShow.contentMode = UIViewContentModeScaleAspectFit;
 

    [self.view addSubview:_produceView];
    [self.view addSubview:_displayView];
    [self.view addSubview:_drawButton];
    [self.view addSubview:_displayType];
    [self.view addSubview:_produceType];
    [self.view addSubview:_glCaptureButton];
}

-(void)glCapture{
    CGRect rect = (CGRect){0,0,_displayView.bounds.size};
    UIImage* kitImage = [myScreenRecorder captureImageWithView:self.view];
    
    rect.size.width*=[UIScreen mainScreen].scale;
    rect.size.height*= [UIScreen mainScreen].scale;
    UIImage* glimage = [ImageTool glToUIImageWithRect:rect];
    UIImage* image = [ImageTool mergerImage:kitImage fristPoint:CGPointZero secodImage:glimage secondPoint:_displayView.frame.origin destSize:kitImage.size];
    [_produceView addSubview:_iconShow];
    _iconShow.image = image;
    
//    UIImageView* imageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"13031I1XF-14H6"]];
//    imageView.frame = CGRectMake(100, 30, 100, 100);
//    [_yuvShowView addSubview:imageView];
}

-(void)GJPullDownView:(GJPullDownView *)pulldownView selectIndex:(NSInteger)index{
    if (pulldownView == _produceType) {
        if ([pulldownView.itemNames[index] isEqualToString:@"手绘"]) {
            if (_drawView == nil) {
                _drawView = [[DrawBoard alloc]initWithFrame:_produceView.bounds];

            }
            [_produceView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            [_produceView addSubview:_drawView];
        }
    }else{
            [myScreenRecorder stopRecord];

            UIView* showView;
            ScreenRecorderType type=screenRecorderRealYUVType;
            switch (pulldownView.currentTag) {
                case screenRecorderRealYUVType:
                {
                    
                    showView = _yuvShowView;
                    type=screenRecorderRealYUVType;
                }
                    break;
                case screenRecorderRealRGBA8Type:
                {
                    showView = _imageShowView;
                    type=screenRecorderRealRGBA8Type;
                }
                    break;
                case screenRecorderRealImageType:
                {
                    showView = _imageShowView;
                    type=screenRecorderRealImageType;
                }
                    
                    break;
                case screenRecorderRealH264Type:
                {
                    if (_yuvShowView == nil) {
                        _yuvShowView = [[OpenGLView20 alloc]initWithFrame:_displayView.bounds];
                    }
                    if (_h264Decoder == nil) {
                        _h264Decoder = [[GJH264Decoder alloc]init];
                        _h264Decoder.delegate = self;
                    }
                    type=screenRecorderRealH264Type;
                    
                    showView = _imageShowView;
                }
                    break;
                case screenRecorderFileType:{
                    if (_movieShow == nil) {
                        _movieShow = [[FilePlayerView alloc]initWithFrame:_displayView.bounds];
                    }
                  
                    type=screenRecorderFileType;
                    showView = _movieShow;
                }
                    break;
                default:
                    break;
            }
          
            
            [_displayView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            [_displayView addSubview:showView];
            myScreenRecorder = [[ScreenRecorder alloc]initWithType:type];
            myScreenRecorder.delegate = self;
            usleep(100);
            [myScreenRecorder startWithView:_produceView fps:15 fileUrl:_fileUrl];
            _drawButton.selected = YES;
        }
    
}
 - (void)viewDidLoad
 {
     [super viewDidLoad];
     [self readyInit];
 }



-(void)ScreenRecorder:(ScreenRecorder *)recorder recorderFile:(NSString *)fileUrl FinishWithError:(NSError *)error{
    
//    NSURLRequest *request =[NSURLRequest requestWithURL:[NSURL URLWithString:[fileUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
//    [_movieShow loadRequest:request];
//    return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [_movieShow setFileURL:[NSURL fileURLWithPath:fileUrl]];
        
        [_movieShow playWithFinish:^(BOOL finished) {
            NSLog(@"play success");
        }];
    });

//    [self.player play];
//    NSLog(@"did play");
}
-(void)ScreenRecorder:(ScreenRecorder *)recorder recorderImage:(UIImage *)image FinishWithError:(NSError *)error{
    dispatch_async(dispatch_get_main_queue(), ^{
        _imageShowView.image = image;
    });
}

-(void)ScreenRecorder:(ScreenRecorder *)recorder recorderRGBA8Data:(NSData *)RGBA8Data FinishWithError:(NSError *)error{
    UIImage* image = [ImageTool convertBitmapRGBA8ToUIImage:(unsigned char *) RGBA8Data.bytes withWidth:recorder.captureView.bounds.size.width withHeight:recorder.captureView.bounds.size.height];
    dispatch_async(dispatch_get_main_queue(), ^{
        _imageShowView.image = image;
    });
}
void pixelBufferReleaseBytesCallback( void * CV_NULLABLE releaseRefCon, const void * CV_NULLABLE baseAddress ){
    NSLog(@"pixelBufferReleaseBytesCallback:%p",releaseRefCon);
    free((void*)baseAddress);
}
-(void)ScreenRecorder:(ScreenRecorder *)recorder recorderYUVData:(NSData *)yuvData FinishWithError:(NSError *)error{
    
//    CVPixelBufferRef pixelBuffer;
//    CGSize size = recorder.captureView.bounds.size;
//    data = malloc(yuvData.length);
//    memcpy(data, yuvData.bytes, yuvData.length);
//    
//    NSDictionary* dic = @{(id)kCVPixelBufferOpenGLESCompatibilityKey:@(YES),(id)kCVPixelBufferHeightKey:@(size.height)};
//    CVPixelBufferCreateWithBytes(NULL, size.width, size.height, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, (void*)data, size.width*size.height, pixelBufferReleaseBytesCallback, nil,(__bridge CFDictionaryRef _Nullable)(dic), &pixelBuffer);
//    
//
//    CIImage* image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
//    UIImage* uimage = [UIImage imageWithCIImage:image];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        _imageShowView.image = uimage;
//        CVPixelBufferRelease(pixelBuffer);
//    });
    
    OpenGLView20* iv = _yuvShowView;
    dispatch_async(dispatch_get_main_queue(), ^{
        [iv displayYUV420pData:(void *)yuvData.bytes width:recorder.captureView.bounds.size.width height:recorder.captureView.bounds.size.height];
    });
}
-(void)ScreenRecorder:(ScreenRecorder *)recorder recorderH264Data:(uint8_t *)buffer withLenth:(long)totalLenth keyFrame:(BOOL)keyFrame dts:(int64_t)dts{
    if (keyFrame) {
        unsigned char * spsppsData = (unsigned char*)malloc(recorder.h264Encoder.parameterSet.length);
        memcpy(spsppsData, (unsigned char *)recorder.h264Encoder.parameterSet.bytes, recorder.h264Encoder.parameterSet.length);
        size_t spsSize = (size_t)spsppsData[0];
//        size_t ppsSize = (size_t)spsppsData[4+ spsSize];
        memcpy(spsppsData, "\x00\x00\x00\x01", 4);
        memcpy(spsppsData+4+spsSize, "\x00\x00\x00\x01", 4);
        [_h264Decoder decodeBuffer:(uint8_t*)spsppsData withLenth:(uint32_t)recorder.h264Encoder.parameterSet.length];
        free(spsppsData);
    }
    [_h264Decoder decodeBuffer:buffer withLenth:(uint32_t)totalLenth];
}
-(void)GJH264Decoder:(GJH264Decoder *)devocer decodeCompleteImageData:(CVImageBufferRef)imageBuffer pts:(uint)pts{
   
//    CVPixelBufferLockBaseAddress(imageBuffer, 0);
//    uint8_t* baseAdd = (uint8_t*)CVPixelBufferGetBaseAddress(imageBuffer);
//    size_t w = CVPixelBufferGetWidth(imageBuffer);
//    size_t h = CVPixelBufferGetHeight(imageBuffer);
//    OSType p =CVPixelBufferGetPixelFormatType(imageBuffer);
//    char* ty = (char*)&p;
//    NSLog(@"ty:%c%c%c%c",ty[3],ty[2],ty[1],ty[0]);
//    size_t q = CVPixelBufferGetDataSize(imageBuffer);
//    size_t s = CVPixelBufferGetPlaneCount(imageBuffer);
//    size_t sd = CVPixelBufferGetBytesPerRow(imageBuffer);
//    size_t sds1 = CVPixelBufferGetWidthOfPlane(imageBuffer, 1);
//    size_t ds1 = CVPixelBufferGetHeightOfPlane(imageBuffer, 1);
//    size_t byr1 = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,1);
//    uint8_t* planeAdd1 = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
//    
//    size_t sds0 = CVPixelBufferGetWidthOfPlane(imageBuffer, 0);
//    size_t ds0 = CVPixelBufferGetHeightOfPlane(imageBuffer, 0);
//    size_t byr0 = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,0);
//
//    uint8_t* planeAdd0 = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
//    NSLog(@"sd:%ld,add:%ld",planeAdd1-planeAdd0,planeAdd0 - baseAdd);
//    static uint8_t* buffer = NULL;
//    if (buffer == NULL) {
//        buffer = (uint8_t*)malloc(w*h*1.5);
//    }
//    for (int i = 0; i<ds0; i++) {
//        memcpy(buffer+i*sds0, planeAdd0+i*byr0, sds0);
//    }
//    for (int i = 0; i<ds1; i++) {
//        memcpy(buffer+w*h + i*sds1 , planeAdd1+i*byr1, sds1);
//    }
//
//    [_yuvShowView displayYUV420pData:buffer width:w height:h];
//    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

   
    CIImage* image = [CIImage imageWithCVPixelBuffer:imageBuffer];
    UIImage* uimage = [UIImage imageWithCIImage:image];
    dispatch_async(dispatch_get_main_queue(), ^{
        _imageShowView.image = uimage;
    });
    
 

}

@end
