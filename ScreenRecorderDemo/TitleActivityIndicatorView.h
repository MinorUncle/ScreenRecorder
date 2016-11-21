//
//  TitleActivityIndicatorView.h
//  play
//
//  Created by tongguan on 16/3/8.
//  Copyright © 2016年 tongguan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TitleActivityIndicatorView : UIView
@property(nonatomic,retain)UIColor* titleColor;
@property(nonatomic) BOOL  hidesWhenNoneMesage;  //defaultis YES
-(instancetype)initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyle)style;
-(void)startAnimatingWithMessage:(NSString*)message;
-(void)stopAnimatingWithMessage:(NSString*)message;
@end
