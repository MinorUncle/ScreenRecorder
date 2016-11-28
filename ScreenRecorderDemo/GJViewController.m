//
//  GJViewController.m
//  Demo
//
//  Created by 未成年大叔 on 16-11-20.
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
//screenRecorderRealYUVType
//screenRecorderFileType
#define SYNCH_CAPTURE 1

#define FPS 30
#define DEFAULT_PRODUCT screenRecorderRealYUVType

@interface GJViewController ()<ScreenRecorderDelegate,GJPullDownViewDelegate,GJH264DecoderDelegate>
{
    DrawBoard *_drawView;

    ScreenRecorder *myScreenRecorder;
    FilePlayerView *_movieShow;
    UIButton* _drawButton;
    UIButton* _glCaptureButton;

    GJPullDownView* _displayType;
    UIView* _produceView;
    UIView* _displayView;
    
    UIImageView* _imageShowView;
    OpenGLView20* _yuvShowView;
    
    GJH264Decoder* _h264Decoder;
    NSURL* _fileUrl;
    
    
    UIImageView* _iconShow;
    UIImageView* _glOverShow;

    NSMutableData* _yuvMutDaba;
    
}
@property(nonatomic,strong)AVPlayer* player;
@property(atomic,strong)NSFileHandle* yuvFileHandle;

-(void)readyInit;

@end

static int yuvHeight=320,yuvWidth=568;
@implementation GJViewController
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];

    [self startWithType:(ScreenRecorderType)_displayType.currentTag];

}

-(void)drawClick:(UIButton*)button
{
    button.selected = !button.selected;
    if (button.selected) {
        if (_displayType.currentTag == screenRecorderFileType) {
            [self startWithType:(ScreenRecorderType)_displayType.currentTag];
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

-(void)yuvWrite:(NSData*)data{

    [_yuvFileHandle writeData:data];
}
-(NSData*)yuvRead{

    int lenth = yuvWidth*yuvHeight*1.5;

    
    NSData* data = [_yuvFileHandle readDataOfLength:lenth];
    if(data.length != lenth){
        NSLog(@"read error data:%lu",(unsigned long)data.length);
        return nil;
    }

    return data;
}

-(void)readyInit
{
    _yuvMutDaba = [[NSMutableData alloc]initWithCapacity:800000];
    NSString* path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    _fileUrl = [NSURL fileURLWithPath:[path stringByAppendingPathComponent:@"test.mp4"]];
//    _fileUrl = [[NSBundle mainBundle]pathForResource:@"2016031903" ofType:@"mp4"];
    _yuvFileHandle = [NSFileHandle fileHandleForUpdatingAtPath:_fileUrl.path];
    if (_yuvFileHandle == nil) {
        [[NSFileManager defaultManager]createFileAtPath:_fileUrl.path contents:nil attributes:nil];
        _yuvFileHandle = [NSFileHandle fileHandleForUpdatingAtPath:_fileUrl.path];
        [_yuvFileHandle seekToFileOffset:0];
        
    }
    
    CGFloat midH = 20.0,midW = 50.0,padding = 5.0;
    int itemCount = 3;
    CGFloat margin = (self.view.bounds.size.width - 2*padding -itemCount*midW)/(itemCount-1);

    
    self.view.backgroundColor = [UIColor whiteColor];
    CGRect rect = self.view.bounds;
    rect.size.height = (rect.size.height-midH)*0.5;
    
    _produceView = [[UIView alloc]initWithFrame:rect];
    _produceView.backgroundColor = [UIColor whiteColor];
    
    rect.origin.y=CGRectGetMaxY(rect)+1;
    rect.size.height = midH;
    rect.origin.x=padding;
    rect.size.width = midW;

    _drawButton = [[UIButton alloc]initWithFrame:rect];
    [_drawButton addTarget:self action:@selector(drawClick:) forControlEvents:UIControlEventTouchUpInside];
    [_drawButton setTitle:@"继续" forState:UIControlStateNormal];
    [_drawButton setTitle:@"暂停" forState:UIControlStateSelected];
    [_drawButton setBackgroundColor:[UIColor grayColor]];
   
    
    rect.origin.x = CGRectGetMaxX(rect) + margin;
    _displayType = [[GJPullDownView alloc]initWithItems:@[@"YUVType",@"RGBA8Type",@"ImageType",@"H264Type",@"FileType"]];
    _displayType.itemTags=@[@(screenRecorderRealYUVType),@(screenRecorderRealRGBA8Type),@(screenRecorderRealImageType),@(screenRecorderRealH264Type),@(screenRecorderFileType)];
    _displayType.currentTag = DEFAULT_PRODUCT;
    _displayType.frame = rect;
    _displayType.listTextFont = [UIFont systemFontOfSize:8.0];
    _displayType.sectionLable.font = [UIFont systemFontOfSize:8.0];

    _displayType.PullDownViewDelegate = self;
    
    rect.origin.x = CGRectGetMaxX(rect) + margin;
    _glCaptureButton = [[UIButton alloc]initWithFrame:rect];
    [_glCaptureButton addTarget:self action:@selector(glCapture) forControlEvents:UIControlEventTouchUpInside];
    [_glCaptureButton setTitle:@"GL截图" forState:UIControlStateNormal];
    _glCaptureButton.titleLabel.font = [UIFont systemFontOfSize:10];
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
    _glOverShow = [[UIImageView alloc]initWithFrame:CGRectMake(100, 10, 150, 150)];
    _glOverShow.image = [UIImage imageNamed:@"13031I1XF-14H6"];
    [_yuvShowView addSubview:_glOverShow];
    
    _drawView = [[DrawBoard alloc] initWithFrame:_produceView.bounds];
//    _drawView.image = [UIImage imageNamed:@"13031I1XF-14H6"];
    _drawView.backgroundColor = [UIColor redColor];
    _drawView.userInteractionEnabled = YES;
    [_produceView addSubview:_drawView];
  

    rect = CGRectMake(0, 0, 100, 80);
    _iconShow = [[UIImageView alloc]initWithFrame:rect];
    _iconShow.layer.borderColor = [UIColor blackColor].CGColor;
    _iconShow.layer.borderWidth = 1.0;
    _iconShow.contentMode = UIViewContentModeScaleAspectFit;
    [_produceView addSubview:_iconShow];

    [self.view addSubview:_produceView];
    [self.view addSubview:_displayView];
    [self.view addSubview:_drawButton];
    [self.view addSubview:_displayType];
    [self.view addSubview:_glCaptureButton];
}

-(void)glCapture{
    [_produceView addSubview:_iconShow];
    CGRect rect = [self getRootFrameWithView:_displayView];
    _iconShow.image = [myScreenRecorder captureGLMixtureWithGLRect:rect AboveView:@[_glOverShow] aboveRect:@[[NSValue valueWithCGRect:[self getRootFrameWithView:_glOverShow]]] belowView:@[self.view] belowRect:@[[NSValue valueWithCGRect:self.view.frame]] hostSize:self.view.bounds.size];;
    
//    UIImageView* imageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"13031I1XF-14H6"]];
//    imageView.frame = CGRectMake(100, 30, 100, 100);
//    [_yuvShowView addSubview:imageView];
}
-(CGRect)getRootFrameWithView:(UIView*)view{
    CGRect rect = view.frame;
    UIView* superView = view.superview;
    while (superView) {
        rect.origin.x += superView.frame.origin.x;
        rect.origin.y += superView.frame.origin.y;
        superView = superView.superview;
    }
    return rect;
}

-(void)GJPullDownView:(GJPullDownView *)pulldownView selectIndex:(NSInteger)index{
   
    [myScreenRecorder stopRecord];
    myScreenRecorder = nil;
    [self startWithType:(ScreenRecorderType)pulldownView.currentTag];
}
-(void)produceYuv{
    dispatch_async(myScreenRecorder.captureQueue, ^{
        
        NSData* data= [self yuvRead];
        while (data.length > 0 && myScreenRecorder.status == screenRecorderRecorderingStatus) {
            [_yuvShowView displayYUV420pData:(void*)data.bytes width:yuvWidth height:yuvHeight];
#if SYNCH_CAPTURE
            UIImage* gl = [ImageTool convertBitmapYUV420PToUIImage:(uint8_t*)data.bytes width:yuvWidth height:yuvHeight];
            [myScreenRecorder serialCaptureWithGLBuffer:gl];
            usleep((1.5/FPS)*1000*1000);

#endif
            data= [self yuvRead];
            usleep((1.0/FPS)*1000*1000);
        }
    });
}
-(void)startWithType:(ScreenRecorderType)recodeType{
    UIView* showView;
    switch (recodeType) {
        case screenRecorderRealYUVType:
        {
            showView = _yuvShowView;
        }
            break;
        case screenRecorderRealRGBA8Type:
        {
            showView = _imageShowView;
        }
            break;
        case screenRecorderRealImageType:
        {
            showView = _imageShowView;
        }
            break;
        case screenRecorderRealH264Type:
        {
            if (_h264Decoder == nil) {
                _h264Decoder = [[GJH264Decoder alloc]init];
                _h264Decoder.delegate = self;
            }
            showView = _imageShowView;
        }
            break;
        case screenRecorderFileType:{

            showView = _yuvShowView;
        }
            break;
        default:
            break;
    }
    
    [_yuvFileHandle seekToFileOffset:0];

    [_displayView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_displayView addSubview:showView];
    myScreenRecorder = [[ScreenRecorder alloc]initWithType:recodeType];
    [myScreenRecorder setDestFileUrl:_fileUrl];
    myScreenRecorder.delegate = self;
    usleep(100);
    [_glOverShow removeFromSuperview];
    if (recodeType == screenRecorderFileType) {
        [_yuvShowView addSubview:_glOverShow];
        [self produceYuv];

#if SYNCH_CAPTURE
         [myScreenRecorder startSerialGLMixtureWithGLRect:[self getRootFrameWithView:_yuvShowView] AboveView:@[_glOverShow] aboveRect:@[[NSValue valueWithCGRect:[self getRootFrameWithView:_glOverShow]]] belowView:@[self.view] belowRect:@[[NSValue valueWithCGRect:self.view.bounds]] hostSize:self.view.bounds.size];
#else
         [myScreenRecorder startGLMixtureWithGLRect:[self getRootFrameWithView:_yuvShowView] AboveView:@[_glOverShow] aboveRect:@[[NSValue valueWithCGRect:[self getRootFrameWithView:_glOverShow]]] belowView:@[self.view] belowRect:@[[NSValue valueWithCGRect:self.view.bounds]] hostSize:self.view.bounds.size fps:FPS];
#endif
    }else{
            yuvWidth = _drawView.bounds.size.width;
            yuvHeight = _drawView.bounds.size.height;
        [myScreenRecorder startWithView:_drawView fps:FPS];
    }

    _drawButton.selected = YES;
} - (void)viewDidLoad
 {
     [super viewDidLoad];
     [self readyInit];
 }



-(void)screenRecorder:(ScreenRecorder *)recorder recorderFile:(NSURL *)fileUrl FinishWithError:(NSError *)error{
    

    dispatch_async(dispatch_get_main_queue(), ^{
        [_yuvShowView removeFromSuperview];
        [_displayView addSubview:_movieShow];
        
        [_movieShow setFileURL:fileUrl];
        
        [_movieShow playWithFinish:^(BOOL finished) {
            NSLog(@"play success");
        }];
    });


}
-(void)screenRecorder:(ScreenRecorder *)recorder recorderImage:(UIImage *)image FinishWithError:(NSError *)error{
    dispatch_async(dispatch_get_main_queue(), ^{
        _imageShowView.image = image;
    });
}

-(void)screenRecorder:(ScreenRecorder *)recorder recorderRGBA8Data:(NSData *)RGBA8Data FinishWithError:(NSError *)error{
    unsigned char* data = malloc(RGBA8Data.length);
    memcpy(data, RGBA8Data.bytes, RGBA8Data.length);
    UIImage* image = [ImageTool convertBitmapRGBA8ToUIImage:data width:recorder.captureSize.width height:recorder.captureSize.height];
    dispatch_async(dispatch_get_main_queue(), ^{
        _imageShowView.image = image;
        free(data);
    });
}
void pixelBufferReleaseBytesCallback( void * CV_NULLABLE releaseRefCon, const void * CV_NULLABLE baseAddress ){
    NSLog(@"pixelBufferReleaseBytesCallback:%p",releaseRefCon);
    free((void*)baseAddress);
}
-(void)screenRecorder:(ScreenRecorder *)recorder recorderYUVData:(NSData *)yuvData FinishWithError:(NSError *)error{
    
//    [recorder serialCaptureWithGLBuffer:yuvData.bytes pixFormat:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange];
//    CVPixelBufferRef pixelBuffer;
//    CGSize size = recorder.captureView.bounds.size;
//    data = malloc(yuvData.length);
//    memcpy(data, yuvData.bytes, yuvData.length);
//    
//    NSDictionary* dic = @{(id)kCVPixelBufferOpenGLESCompatibilityKey:@(YES),(id)kCVPixelBufferHeightKey:@(size.height)};
//    CVPixelBufferCreateWithBytes(NULL, size.width, size.height, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, (void*)data, size.width*size.height, pixelBufferReleaseBytesCallback, nil,(__bridge CFDictionaryRef _Nullable)(dic), &pixelBuffer);
//    
//    CIImage* image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
//    UIImage* uimage = [UIImage imageWithCIImage:image];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        _imageShowView.image = uimage;
//        CVPixelBufferRelease(pixelBuffer);
//    });
//    static int count = 0;
//    if (count++>10) {
//        return;
//    }
    if (_displayType.currentTag == screenRecorderRealYUVType) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self yuvWrite:yuvData];
        });
    }
    OpenGLView20* iv = _yuvShowView;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [iv displayYUV420pData:(void *)yuvData.bytes width:recorder.captureSize.width height:recorder.captureSize.height];
    });
}
-(void)screenRecorder:(ScreenRecorder *)recorder recorderH264Data:(uint8_t *)buffer withLenth:(long)totalLenth keyFrame:(BOOL)keyFrame dts:(int64_t)dts{
    if (keyFrame) {
        unsigned char * spsppsData = (unsigned char*)malloc(recorder.h264Encoder.parameterSet.length);
        memcpy(spsppsData, (unsigned char *)recorder.h264Encoder.parameterSet.bytes, recorder.h264Encoder.parameterSet.length);
        size_t spsSize = (size_t)spsppsData[0];
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
