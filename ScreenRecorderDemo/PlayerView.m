//
//  PlayerView.m
//  AiDuoKe
//
//  Created by tongguan on 16/3/28.
//  Copyright © 2016年 TGtech. All rights reserved.
//

#import "PlayerView.h"
#import "TitleActivityIndicatorView.h"

#define HIDE_TIME 20

@interface PlayerView()
{
    TitleActivityIndicatorView* _activityIndicator;
}
@property(nonatomic,retain)NSTimer* timer;
@end

@implementation PlayerView
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _contentView = [[UIView alloc]initWithFrame:self.bounds];
        [self addSubview:_contentView];
        _activityIndicator = [[TitleActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityIndicator.titleColor = [UIColor whiteColor];
        [self.contentView addSubview: _activityIndicator];
        _activityIndicator.center = self.contentView.center;

   
        _timer = [NSTimer scheduledTimerWithTimeInterval:HIDE_TIME target:self selector:@selector(hideContent) userInfo:nil repeats:NO];
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapClick:)];
        [self addGestureRecognizer:tap];
    }
    return self;
}
-(void)playWithFinish:(FinishBlock)finishBlock{}
-(void)stop{}
-(void)pause{}
-(void)seekToValue:(long)value finished:(FinishBlock)finishBlock{}
-(void)thumbnailImageWithName:(NSString *)name resultBlock:(void (^)(UIImage *))resultBlock{}

-(void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    _contentView.frame = self.bounds;
    _activityIndicator.center = self.contentView.center;
}
-(void)tapClick:(UITapGestureRecognizer*)tap{
    if (_contentView.alpha < 1.0) {
        _contentView.alpha = 1.0;
        if (_timer.isValid) {
            _timer.fireDate = [NSDate dateWithTimeIntervalSinceNow:HIDE_TIME];
        }else{
            _timer = [NSTimer scheduledTimerWithTimeInterval:HIDE_TIME target:self selector:@selector(hideContent) userInfo:nil repeats:NO];
        }
    }else{
        [_timer invalidate];
        [self hideContent];
    }
}
-(void)hideContent{
    [_timer invalidate];
    NSLog(@"fire");
    static BOOL completed = YES;
    if (completed == NO) {
        return;
    }
    completed = NO;
    [UIView animateWithDuration:0.4 animations:^{
        _contentView.alpha = 0.0;
    }completion:^(BOOL finished) {
        completed = YES;
    }];
}

-(void)setStatus:(BasePlayerStatus)status{
    _status = status;
    switch (status) {
        case basePlayerStatusStop:
        {
            [UIApplication sharedApplication].idleTimerDisabled = NO;
            [_activityIndicator stopAnimatingWithMessage:nil];
        }
            break;
        case basePlayerStatusPlay:
        {
            [UIApplication sharedApplication].idleTimerDisabled = YES;
            [_activityIndicator stopAnimatingWithMessage:nil];
        }
            break;
        case basePlayerStatusPause:
        {
            [_activityIndicator stopAnimatingWithMessage:nil];
        }
            break;
        case basePlayerStatusWaitting:
        {
            [_activityIndicator startAnimatingWithMessage:@"请求中..."];
        }
            break;
        default:
            break;
    }
}
-(void)tipInViewWithMessage:(NSString*)message animation:(BOOL)animation{
    if (!animation) {
        [_activityIndicator stopAnimatingWithMessage:message];
    }else{
        [_activityIndicator startAnimatingWithMessage:message];
    }
}

-(void)dealloc{
    NSLog(@"playerView delloc:%@",self);
    if (_timer.isValid) {
        [_timer invalidate];
    }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
