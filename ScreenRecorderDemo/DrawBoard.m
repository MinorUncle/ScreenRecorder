//
//  DrawBoard.m
//  ScreenRecorderDemo
//
//  Created by 未成年大叔 on 16/11/20.
//  Copyright © 2016年 lezhixing. All rights reserved.
//

#import "DrawBoard.h"
#import <OpenGLES/ES2/gl.h>
@interface DrawBoard()
{
    NSMutableArray* _points;
    CGMutablePathRef _path;
}
@end

@implementation DrawBoard
- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}
-(void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(ctx, [UIColor yellowColor].CGColor);
    CGContextSetFillColorWithColor(ctx, [UIColor clearColor].CGColor);
    CGContextSetLineWidth(ctx, 5.0);
    CGContextAddPath(ctx, _path);
    CGContextStrokePath(ctx);

}



-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"touch begin");
    if (_path == NULL) {
        _path = CGPathCreateMutable();
    }
    UITouch* touch = [touches anyObject];

    
    CGPoint point = [touch locationInView:self];
    CGPathMoveToPoint(_path, NULL, point.x, point.y);
    
}
-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch* touch = [touches anyObject];
    if (touch.tapCount == 2) {
        NSLog(@"touch moved");
        CGPathRelease(_path);
        _path = NULL;
        [self setNeedsDisplay];
        return;
    }
    
    CGPoint point = [touch locationInView:self];
    CGPathAddLineToPoint(_path, NULL, point.x, point.y);
    [self setNeedsDisplay];
}
@end
