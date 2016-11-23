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
    BOOL _needUpdate;
    int _fps;
    NSTimer* _updateTimer;
    CGPoint _previousPoint; //1 point behind

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
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _init];
    }
    return self;
}
-(void)_init{
    _fps = 20;
    _updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/_fps target:self selector:@selector(updateUI) userInfo:nil repeats:YES];
}

-(void)updateUI{
    if (_needUpdate) {
        [self setNeedsDisplay];
        _needUpdate = NO;
        NSLog(@"updaui didupdate:%@",[NSThread currentThread]);

    }
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

-(void)drawLineFromPoint:(CGPoint)fPoint ToPoint:(CGPoint)tPoint
{
//    UIGraphicsBeginImageContext(self.frame.size);
//    [self.image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
//    CGContextRef ctx = UIGraphicsGetCurrentContext();
//    CGContextSetLineCap(ctx, kCGLineCapRound);
//    CGContextSetLineWidth(ctx, 7);
//    CGContextSetStrokeColorWithColor(ctx, [UIColor yellowColor].CGColor);
//    CGContextMoveToPoint(ctx, fPoint.x, fPoint.y);
//    CGContextAddLineToPoint(ctx, tPoint.x, tPoint.y);
//    CGContextStrokePath(ctx);
//    self.image = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"touch begin");
    if (_path == NULL) {
        _path = CGPathCreateMutable();
    }
    UITouch* touch = [touches anyObject];
    
    
    CGPoint point = [touch locationInView:self];
    _previousPoint = point;
    CGPathMoveToPoint(_path, NULL, point.x, point.y);
    
}
-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch* touch = [touches anyObject];
    if (touch.tapCount == 2) {
        NSLog(@"touch moved");
        CGPathRelease(_path);
        _path = NULL;
        _needUpdate = YES;
        return;
    }
    
    CGPoint point = [touch locationInView:self];
//    [self drawLineFromPoint:_previousPoint ToPoint:point];
    _previousPoint = point;
    CGPathAddLineToPoint(_path, NULL, point.x, point.y);
//    [self setNeedsDisplay];
    _needUpdate = YES;
}
-(void)dealloc{
    [_updateTimer invalidate];
    _updateTimer = NULL;
}
@end
