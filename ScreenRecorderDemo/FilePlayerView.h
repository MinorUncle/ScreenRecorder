//
//  FilePlayerView.h
//  AiDuoKe
//
//  Created by tongguan on 16/3/28.
//  Copyright © 2016年 TGtech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlayerView.h"


@interface FilePlayerView : PlayerView
@property(nonatomic,copy)NSURL* fileURL;
@property(nonatomic,assign,readonly)Float64 loadedTimeLenth;

#pragma mark function

@end
