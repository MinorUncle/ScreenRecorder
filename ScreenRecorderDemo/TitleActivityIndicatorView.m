//
//  TitleActivityIndicatorView.m
//  play
//
//  Created by tongguan on 16/3/8.
//  Copyright © 2016年 tongguan. All rights reserved.
//

#import "TitleActivityIndicatorView.h"
@interface TitleActivityIndicatorView()
{
    
}
@property(nonatomic,strong) UIActivityIndicatorView* activity;
@property(nonatomic,strong) UILabel* titleLab;
//@property(nonatomic,weak) UIView* superV;

@end
@implementation TitleActivityIndicatorView
-(instancetype)initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyle)style{
    self = [super init];
    if (self) {
        _activity = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:style];
        [self addSubview:_activity];
        [self addSubview:self.titleLab];
        self.titleLab.font = [UIFont systemFontOfSize:14];

    }
    return self;
}
-(void)setFrame:(CGRect)frame{
    CGRect rect = CGRectMake(0, 0, 20, 20);
   
    rect.origin.y = 0;
    rect.origin.x = (frame.size.width - rect.size.width)*0.5;
    CGSize size = [@"h" sizeWithAttributes:@{NSFontAttributeName:self.titleLab.font}];
    self.titleLab.frame = CGRectMake(0, rect.size.height, rect.size.width, size.height);
    rect.size.height += size.height;
    frame.size = rect.size;
    
    [super setFrame:frame];
    
}

-(void)setTitleColor:(UIColor *)titleColor{
   
    _titleColor = titleColor;
    self.titleLab.textColor = titleColor;
}
-(UILabel *)titleLab{
    if (_titleLab == nil) {
        _titleLab = [[UILabel alloc]init];
        _titleLab.font = [UIFont systemFontOfSize:11];
        _titleLab.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLab;
}
-(void)setHidesWhenNoneMesage:(BOOL)hidesWhenNoneMesage{
    _hidesWhenNoneMesage = hidesWhenNoneMesage;
    if (_hidesWhenNoneMesage &&  ([_titleLab.text isEqualToString:@""] && _titleLab.text == nil)) {
        self.alpha = 1.0;
    }
}
//-(void)willMoveToSuperview:(UIView *)newSuperview{
//    [super willMoveToSuperview:newSuperview];
//    self.superV = newSuperview;
//}

-(void)startAnimatingWithMessage:(NSString *)message{
    _titleLab.text = message;
    if (message != nil && ![message isEqualToString:@""]) {
        CGSize size = [message sizeWithAttributes:@{NSFontAttributeName:self.titleLab.font}];
        CGRect rect = _titleLab.frame;
        rect.size = size;
        rect.origin.x = (self.frame.size.width - rect.size.width)*0.5;
        _titleLab.frame = rect;
    }
    self.alpha = 1.0;
    [self.activity startAnimating];
}
-(void)stopAnimatingWithMessage:(NSString *)message{
    
    _titleLab.text = message;
    if (message != nil && ![message isEqualToString:@""]) {
        CGSize size = [message sizeWithAttributes:@{NSFontAttributeName:self.titleLab.font}];
        CGRect rect = _titleLab.frame;
        rect.size = size;
        rect.origin.x = (self.frame.size.width - rect.size.width)*0.5;
        _titleLab.frame = rect;
        self.alpha = 1.0;
    }else{
        self.alpha = 0.0;

    }
    [self.activity stopAnimating];
}

-(void)dealloc{
}
@end
