//
//  FilePlayerView.m
//  AiDuoKe
//
//  Created by tongguan on 16/3/28.
//  Copyright © 2016年 TGtech. All rights reserved.
//

#import "FilePlayerView.h"
#import <AVFoundation/AVFoundation.h>
//#import "NetDefine.h"


@interface FilePlayerView()
{
}
@property(nonatomic,retain)AVPlayer* player;
@property(nonatomic,retain)AVPlayerLayer* playerLayer;
@property(nonatomic,retain)AVPlayerItem* playerItem;
@property(nonatomic,copy)FinishBlock playFinishBlock;
@property(nonatomic,assign)Float64 temJumpValue;


@end
@implementation FilePlayerView
@synthesize playerItem = _playerItem;
- (void)_init
{
    
        _player = [[AVPlayer alloc]init];
        _playerLayer = (AVPlayerLayer*)self.layer;
        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        _playerLayer.player = _player;
        _playerLayer.backgroundColor = [UIColor blackColor].CGColor;
        [self addAVPlayerObserver];
        __weak FilePlayerView* weekSelf = self;
        [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:nil usingBlock:^(CMTime time) {
            weekSelf.currentTime = (time.value)/time.timescale;
//            NSLog(@"currentTime：%ld",weekSelf.currentTime);
            if (weekSelf.currentChangeBlock != nil) {
                weekSelf.currentChangeBlock(weekSelf.currentTime);
            }
        }];
}
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _init];
    }
    return self;
}

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}
-(void)setFileURL:(NSURL *)fileURL{
    if (fileURL == nil) {
        return;
    }
    _fileURL = fileURL;
//    _fileURL = [NSURL URLWithString:@"http://yd.cdsoda.cn/gssp/2016031903.mp4"];
//    _fileURL = [NSURL URLWithString:@"http://139.196.21.71:8000/0_1_2344883527_3521_16777216123123607_1_1463644488.m3u8"];

//    NSString * docPath =  NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
//    docPath = [NSString stringWithFormat:@"%@/test.mp4",docPath];
//    NSString* p = [[NSBundle mainBundle] pathForResource:@"1" ofType:@"mp4"];
//    _fileURL = [NSURL fileURLWithPath:p];
    self.playerItem = [AVPlayerItem playerItemWithURL:_fileURL];
}

-(void)playEnd{
    self.status = basePlayerStatusStop;
    NSLog(@"play end");
}
-(void)playWithFinish:(FinishBlock)finishBlock{
    if (self.status == basePlayerStatusPlay || self.status == basePlayerStatusWaitting) {
        finishBlock(NO);
        return;
    }
    if(self.playerItem == nil){
        [self tipInViewWithMessage:@"播放失败,文件不存在" animation:NO];
        if(finishBlock){
            finishBlock(NO);
        }
        return;
    }
    

    self.status = basePlayerStatusWaitting;
    [self.player play];

    if (self.playerItem.playbackLikelyToKeepUp) {
        self.status = basePlayerStatusPlay;
        if (finishBlock != nil) {
            finishBlock(YES);
        }
        return;
    }
    __weak FilePlayerView* weekSelf = self;
    self.playFinishBlock = ^(BOOL finish){
         weekSelf.status = basePlayerStatusPlay;
        if (finishBlock != nil) {
            finishBlock(finish);
        }
    };

}
-(void)pause{
    [self.player pause];
    self.status = basePlayerStatusPause;
}
-(void)stop{
    [self.player pause];
    self.status = basePlayerStatusStop;
}
-(long)totalTime{
    if (self.playerLayer != nil) {
        super.totalTime = CMTimeGetSeconds(self.player.currentItem.duration);
    }else{
        super.totalTime = 0;
    }
    return super.totalTime;
}
-(void)seekToValue:(long)value finished:(void (^)(BOOL finished))finishBlock{
    self.temJumpValue = value;
    if (self.totalTime == 0) {
        if (finishBlock != nil) {
            finishBlock(NO);
        }
        return;
    }
    self.playFinishBlock = ^(BOOL finish){
        if (finishBlock != nil) {
            finishBlock(finish);
        }
    };
    self.status = basePlayerStatusWaitting;
    [self.player seekToTime:CMTimeMake(value, 1) toleranceBefore:CMTimeMake(1, 30) toleranceAfter:CMTimeMake(1, 30) completionHandler:^(BOOL finished) {
        [self.player play];
        self.status = basePlayerStatusPlay;
    }];
}


#pragma mark AVPLAYER
-(void)setPlayerItem:(AVPlayerItem *)playerItem{
    [_playerItem removeObserver:self forKeyPath:@"duration"];
    [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [_playerItem removeObserver:self forKeyPath:@"playbackBufferFull"];
    [_playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [_playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    if (self.player.currentItem != playerItem) {
        [self.player replaceCurrentItemWithPlayerItem:playerItem];
        
    }

    _playerItem = playerItem;
//    _playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = YES;
    [_playerItem addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:@"playbackBufferFull" options:NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];

    [_playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];


}

-(void)addAVPlayerObserver
{
    [self.player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaDidNotArrive:) name:AVPlayerItemPlaybackStalledNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(errorlog:) name:AVPlayerItemNewErrorLogEntryNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileToEndTime:) name:AVPlayerItemFailedToPlayToEndTimeErrorKey object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timeJumped:) name:AVPlayerItemTimeJumpedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(AccessLogEntry:) name:AVPlayerItemNewAccessLogEntryNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FailedToPlayToEndTime:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];

}

-(void)removeAVPlayerObserver
{
    [self.player removeObserver:self forKeyPath:@"status"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemNewErrorLogEntryNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeErrorKey object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemTimeJumpedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemNewAccessLogEntryNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];

    
    [self.playerItem removeObserver:self forKeyPath:@"duration"];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferFull"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [_playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];


}
-(void)timeJumped:(id)n{
    NSLog(@"timeJumped:%@",n);
}
-(void)AccessLogEntry:(id)n{
    NSLog(@"AccessLogEntry:%@",n);
}
-(void)FailedToPlayToEndTime:(id)n{
    NSLog(@"FailedToPlayToEndTime:%@",n);
}
-(void)fileToEndTime:(id)e{
    NSLog(@"fileToEndTime:%@",e);
}
-(void)mediaDidNotArrive:(id)n{
    NSLog(@"未到达%@",n);
    self.status = basePlayerStatusWaitting;
    __weak FilePlayerView* weekSelf = self;
    if (self.playFinishBlock == nil) {
        self.playFinishBlock = ^(BOOL finish){
            weekSelf.status = basePlayerStatusPlay;
        };
    }
  
    

}
-(void)errorlog:(id)n{
    NSLog(@"错误AVPlayerItemNewErrorLogEntryNotification：%@",n);
}

-(AVPlayerItem*)playerItem{
    if (_playerItem == nil) {
        _playerItem = [[AVPlayerItem alloc]initWithURL:_fileURL];
        [_playerItem addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionNew context:nil];
        [_playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        [_playerItem addObserver:self forKeyPath:@"playbackBufferFull" options:NSKeyValueObservingOptionNew context:nil];
        [_playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
        [_playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];

    }
    return _playerItem;
}



-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)contex
{
    if([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [change[@"new"] integerValue];
        switch (status) {
            case AVPlayerStatusUnknown:
                NSLog(@"AVPlayerStatusUnknown");
                self.status = basePlayerStatusStop;
                break;
            case AVPlayerStatusFailed:
                NSLog(@"AVPlayerStatusFailed");
                self.status = basePlayerStatusStop;
                break;
            case AVPlayerStatusReadyToPlay:
                NSLog(@"AVPlayerStatusReadyToPlay");
//                self.status = basePlayerStatusPlay;
                break;
            default:
                break;
        }
    }else if ([keyPath isEqualToString:@"duration"]){
        self.totalTime = CMTimeGetSeconds(self.player.currentItem.duration);
        if (self.totalChangeBlock != nil) {
            self.totalChangeBlock(self.totalTime);
        }
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]){
//        if (self.playFinishBlock != nil) {
//            if ([self dealJumpTime]) {
//                [self.player play];
//            } ;
//        }
    }else if([keyPath isEqualToString:@"playbackLikelyToKeepUp"]){
        NSLog(@"playbackLikelyToKeepUp：%d",self.playerItem.playbackLikelyToKeepUp);
        if (self.playerItem.playbackLikelyToKeepUp) {
            if (self.playFinishBlock != nil) {
                self.status = basePlayerStatusPlay;
                self.playFinishBlock(YES);
                self.playFinishBlock = nil;
            }
            
        }
    
    }else if ([keyPath isEqualToString:@"playbackBufferFull"]){
        NSLog(@"playbackBufferFull：%d",self.playerItem.playbackBufferFull);

    }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]){
        NSLog(@"playbackBufferEmpty：%d",self.playerItem.isPlaybackBufferEmpty);
        self.status = basePlayerStatusWaitting;
        __weak FilePlayerView* weekSelf = self;
        if (self.playFinishBlock == nil) {
            self.playFinishBlock = ^(BOOL finish){
                weekSelf.status = basePlayerStatusPlay;
            };
        }
        
    }
}
-(void)setVolume:(float)volume{
    [super setVolume:volume];
    [self.player setVolume:volume];
}

//-(BOOL)dealJumpTime{
//    NSArray<NSValue*>* arry = self.playerItem.loadedTimeRanges;
//    BOOL content = NO;
//    for (NSValue* value in arry) {
//        CMTimeRange range = [value CMTimeRangeValue];
//        
//        Float64 start = CMTimeGetSeconds(range.start);
//        Float64 end = CMTimeGetSeconds(CMTimeAdd(range.start, range.duration));
//       // NSLog(@"start:%f   end:%f  value:%f",start,end,_temJumpValue);
//        if (start <= _temJumpValue && end > _temJumpValue+0.1 ) {
//            content = YES;
//            break;
//        }
//    }
//    if (content) {
//        self.status = basePlayerStatusPlay;
//        if (self.playFinishBlock != nil) {
//            self.playFinishBlock(YES);
//            self.playFinishBlock = nil;
//        }
//       
//    }
//    return content;
//}
/**
 *  截取指定时间的视频缩略图
 *
 *  @param timeBySecond 时间点
 */
-(void)thumbnailImageWithName:(NSString*)name resultBlock:(void(^)(UIImage* img))resultBlock
{
    //创建URL
    //根据url创建AVURLAsset
    AVURLAsset *urlAsset= (AVURLAsset*)self.playerItem.asset;
    //根据AVURLAsset创建AVAssetImageGenerator
    AVAssetImageGenerator *imageGenerator=[AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
    /*截图
     * requestTime:缩略图创建时间
     * actualTime:缩略图实际生成的时间
     */
      CMTime time=CMTimeMakeWithSeconds(1, 1);//CMTime是表示电影时间信息的结构体，第一个参数表示是视频第几秒，第二个参数表示每秒帧数.(如果要活的某一秒的第几帧可以使用CMTimeMake方法)
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error=nil;
        CGImageRef cgImage= [imageGenerator copyCGImageAtTime:time actualTime:NULL error:&error];
        if(error){
            NSLog(@"截取视频缩略图时发生错误，错误信息：%@",error.localizedDescription);
            if (resultBlock!= nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(nil);
                });
            }
            return;
        }
        UIImage *image=[UIImage imageWithCGImage:cgImage];//转化为UIImage
        
        NSString * docPath =  NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
        
        docPath = [NSString stringWithFormat:@"%@/%@",docPath,name];
        NSString* fileName = [docPath lastPathComponent];
        docPath = [docPath substringToIndex:docPath.length - fileName.length-1];
        [[NSFileManager defaultManager] createDirectoryAtPath:docPath withIntermediateDirectories:YES attributes:nil error:nil];
        NSString * picturePath = [NSString stringWithFormat:@"%@/%@",docPath,fileName];
        NSData* imgData = UIImagePNGRepresentation(image);
        BOOL save = [[NSFileManager defaultManager]createFileAtPath:picturePath contents:imgData attributes:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (save) {
                if (resultBlock!= nil) {
                    resultBlock(image);
                }
            }else{
                if (resultBlock!= nil) {
                    resultBlock(nil);
                }
            }
        });
                //保存到相册
        CGImageRelease(cgImage);
    });
}

-(void)dealloc{
    if(self.playerLayer != nil){
        [self removeAVPlayerObserver];
    }
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [_player seekToTime:kCMTimeZero toleranceBefore:CMTimeMake(1, 1) toleranceAfter:CMTimeMake(1, 1)];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
