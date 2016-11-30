//
//  GJViewController.m
//  Demo
//
//  Created by 未成年大叔 on 16-11-20.
//  Copyright (c) 2016年 . All rights reserved.
//

#import <ReplayKit/ReplayKit.h>

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

#define FPS 15
#define DEFAULT_PRODUCT screenRecorderRealYUVType

@interface GJViewController ()<ScreenRecorderDelegate,GJPullDownViewDelegate,GJH264DecoderDelegate,RPBroadcastActivityViewControllerDelegate,RPScreenRecorderDelegate,RPBroadcastControllerDelegate>
{
    DrawBoard *_drawView;//手绘

    ScreenRecorder *myScreenRecorder;//录屏
    FilePlayerView *_movieShow; //文件播放显示
    UIButton* _drawButton;
    UIButton* _glCaptureButton;

    GJPullDownView* _displayType;
    UIView* _produceView; //产生数据层
    UIView* _displayView; //显示层
    
    UIImageView* _imageShowView; //图片显示
    OpenGLView20* _yuvShowView; //yuv播放显示
    
    GJH264Decoder* _h264Decoder; //编码器
    NSURL* _fileUrl;
    
    
    UIImageView* _iconShow; //gl截图显示
    UIImageView* _glOverShow; //gl遮盖层

    NSMutableData* _yuvMutDaba;
    
    UIButton* _replayPush;
    
    
}
@property(nonatomic,strong)AVPlayer* player;
@property(atomic,strong)NSFileHandle* yuvFileHandle;
@property(atomic,strong)RPBroadcastController* broadcast;

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
    
    [RPScreenRecorder sharedRecorder].microphoneEnabled = YES;
    [RPScreenRecorder sharedRecorder].cameraEnabled = YES;
    
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
    int itemCount = 4;
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
    
    rect.origin.x = CGRectGetMaxX(rect) + margin;
    _replayPush = [[UIButton alloc]initWithFrame:rect];
    [_replayPush addTarget:self action:@selector(boardCast:) forControlEvents:UIControlEventTouchUpInside];
    [_replayPush setTitle:@"replay开始" forState:UIControlStateNormal];
    [_replayPush setTitle:@"replay停止" forState:UIControlStateSelected];

    _replayPush.titleLabel.font = [UIFont systemFontOfSize:10];
    [_replayPush setBackgroundColor:[UIColor grayColor]];

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
    _iconShow.contentMode = UIViewContentModeScaleAspectFit;
    [_produceView addSubview:_iconShow];

    [self.view addSubview:_produceView];
    [self.view addSubview:_displayView];
    [self.view addSubview:_drawButton];
    [self.view addSubview:_displayType];
    [self.view addSubview:_glCaptureButton];
    [self.view addSubview:_replayPush];

}

-(void)glCapture{
    [_produceView addSubview:_iconShow];
    _iconShow.image = [myScreenRecorder captureImageWithView:self.view];
    
//    UIImageView* imageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"13031I1XF-14H6"]];
//    imageView.frame = CGRectMake(100, 30, 100, 100);
//    [_yuvShowView addSubview:imageView];
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
            @synchronized ([UIScreen mainScreen]) {
                [_yuvShowView displayYUV420pData:(void*)data.bytes width:yuvWidth height:yuvHeight];
            }

            usleep((1.0/FPS)*1000*1000);
            data= [self yuvRead];
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
    if (recodeType == screenRecorderFileType) {
        [self produceYuv];
        [myScreenRecorder startWithView:self.view fps:FPS];
        
        [UIView animateWithDuration:3.0 animations:^{
            _glOverShow.alpha= 0.0;
        }completion:^(BOOL finished) {
            _glOverShow.alpha=1.0;
        }];
        
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
    if(_displayType.currentTag != screenRecorderFileType)return;
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
    UIImage* image = [ImageTool convertBitmapRGBA8ToUIImage:data width:recorder.captureFrame.size.width height:recorder.captureFrame.size.height];
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
        dispatch_sync(dispatch_get_global_queue(0, 0), ^{
            [self yuvWrite:yuvData];
        });
    }
    OpenGLView20* iv = _yuvShowView;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [iv displayYUV420pData:(void *)yuvData.bytes width:recorder.captureFrame.size.width height:recorder.captureFrame.size.height];
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


#pragma mark replay
-(void)boardCast:(UIButton*)btn{
    if (![RPScreenRecorder sharedRecorder].isRecording) {
        btn.selected = YES;
        __weak GJViewController* wk = self;
        [RPBroadcastActivityViewController loadBroadcastActivityViewControllerWithHandler:^(RPBroadcastActivityViewController * _Nullable broadcastActivityViewController, NSError * _Nullable error) {
            if (error) {
                NSLog(@"loadBroadcast error:%@",error);
            }else{
                broadcastActivityViewController.delegate = wk;
                [wk presentViewController:broadcastActivityViewController animated:YES completion:nil];
            }
        }];
    }else{
        btn.selected = NO;
       [self.broadcast finishBroadcastWithHandler:^(NSError * _Nullable error) {
           NSLog(@"finishBroadcast  error:%@",error);
       }];
        [[RPScreenRecorder sharedRecorder] stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
        }];
    }
}
- (void)broadcastActivityViewController:(RPBroadcastActivityViewController *)broadcastActivityViewController didFinishWithBroadcastController:(nullable RPBroadcastController *)broadcastController error:(nullable NSError *)error{
    [broadcastActivityViewController dismissViewControllerAnimated:YES completion:nil];
    if (error) {
        NSLog(@"loadBroadcast error:%@",error);
    }else{
        [broadcastController startBroadcastWithHandler:^(NSError * _Nullable error) {
            NSLog(@"startBroadcast  error:%@",error);
            self.broadcast = broadcastController;
            broadcastController.delegate = self;
            UIView* view = [[RPScreenRecorder sharedRecorder] cameraPreviewView];
            view.contentMode = UIViewContentModeCenter;
            view.frame = _iconShow.bounds;
            view.center = _iconShow.center;
            [_iconShow addSubview:view];
        }];
    }}

- (void)broadcastController:(RPBroadcastController *)broadcastController didFinishWithError:(NSError * __nullable)error{
    NSLog(@"didFinishWithError error :%@",error);
}
- (void)broadcastController:(RPBroadcastController *)broadcastController didUpdateServiceInfo:(NSDictionary <NSString *, NSObject <NSCoding> *> *)serviceInfo{
    NSLog(@"error:%@",serviceInfo);
}

@end
