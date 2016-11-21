//
//  PlayerView.h
//  AiDuoKe
//
//  Created by tongguan on 16/3/28.
//  Copyright © 2016年 TGtech. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum BasePlayerStatus_{
    basePlayerStatusStop,
    basePlayerStatusPlay,
    basePlayerStatusPause,
    basePlayerStatusWaitting
}BasePlayerStatus;
typedef void(^LongChange)(long value);
typedef void(^FinishBlock)(BOOL finished);


@interface PlayerView : UIView
@property(assign,nonatomic)BasePlayerStatus status;
@property(assign,nonatomic)long totalTime;
@property(assign,nonatomic)long currentTime;
@property(assign,nonatomic)float volume;
@property(copy,nonatomic)LongChange currentChangeBlock;
@property(copy,nonatomic)LongChange totalChangeBlock;

@property(nonatomic,retain)UIView* contentView;
-(void)tipInViewWithMessage:(NSString*)message animation:(BOOL)animation;
-(void)playWithFinish:(FinishBlock)finishBlock;
-(void)stop;
-(void)pause;
-(void)seekToValue:(long)value finished:(FinishBlock)finishBlock;

-(void)thumbnailImageWithName:(NSString*)name resultBlock:(void(^)(UIImage* img))resultBlock;

@end
