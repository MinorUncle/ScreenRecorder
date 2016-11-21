//
//  GJPullDownView.m
//  GJPullDownViewDemo
//
//  Created by tongguan on 16/1/9.
//  Copyright © 2016年 tongguan. All rights reserved.
//

#import "GJPullDownView.h"

#define FONT_SIZE 12
@interface GJPullDownView ()<UITableViewDataSource,UITableViewDelegate>
{
    CGFloat _cellHeight;
    UIButton* _sectionBtn;
    UIView* _temSuperView;
}
@property(strong,nonatomic)UIButton* backGroundView;

@property(strong,nonatomic)UIImageView* arrow;

@end
@implementation GJPullDownView
@synthesize isOpen = _isOpen,itemTags = _itemTags;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor =[ UIColor whiteColor];
        _sectionBtn =  [[ UIButton alloc]initWithFrame:self.bounds];
        self.layer.borderColor = [UIColor grayColor].CGColor;
        self.layer.borderWidth = 1.0;
        self.layer.cornerRadius = 5.0;
        self.layer.masksToBounds = YES;
        [_sectionBtn addTarget:self action:@selector(selectBtn:) forControlEvents:UIControlEventTouchUpInside];
        _sectionLable = [[UILabel alloc]init];
        _sectionLable.textAlignment = NSTextAlignmentCenter;

        [_sectionBtn addSubview:_sectionLable];
        CGRect rect = _sectionBtn.bounds;
        rect.origin.y = CGRectGetMaxY(frame);
        rect.size.height = 0.0;
        _listView = [[UITableView alloc]initWithFrame:rect];
        _listView.backgroundColor = [UIColor whiteColor];
        _listView.bounces = NO;
        _listView.delegate = self;
        _listView.dataSource =self;
        [self addSubview:_sectionBtn];
        [self.superview addSubview:_listView];
        
        self.accessViewType = AccessViewTypeArrow;
        _listTextFont = [UIFont systemFontOfSize:FONT_SIZE];
        
    }
    return self;
}

-(void)drawRect:(CGRect)rect{
    if (self.accessViewType == AccessViewTypeArrow) {
        self.arrow.image = [self drawImageWithType:AccessViewTypeArrow];
    }
}
-(UIImageView *)arrow{
    if(_arrow == nil){
        _arrow = [[UIImageView alloc]init];
        [self setNeedsDisplay];
    }
    return _arrow;
}
-(UIImage*)drawImageWithType:(AccessViewType)type{
    UIImage* image;
    switch (type) {
        case AccessViewTypeArrow:
        {
            CGSize size = CGSizeMake(self.bounds.size.height*0.8,self.bounds.size.height*0.5);
            UIGraphicsBeginImageContextWithOptions(size, NO, 0);
            CGContextRef con = UIGraphicsGetCurrentContext();
            if (con == nil) {
                return nil;
            }
            CGContextSetLineWidth(con, 2);
            CGContextSetStrokeColorWithColor(con, [UIColor grayColor].CGColor);
            CGContextMoveToPoint(con, 0, 0);
            CGContextAddLineToPoint(con, size.width*0.5, size.height);
            CGContextAddLineToPoint(con, size.width, 0);
            CGContextStrokePath(con);
            image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
            break;
        default:
            break;
    }
    return image;
}

-(void)setAccessViewType:(AccessViewType)accessViewType{
    if (accessViewType == _accessViewType) {
        return;
    }
    _accessViewType = accessViewType;
    switch (accessViewType) {
        case AccessViewTypeCustom:
            [self.arrow removeFromSuperview];
            break;
        case AccessViewTypeArrow:
            self.accessView = self.arrow;
            break;
        default:
            break;
    }

}
- (instancetype)initWithItems:(NSArray*)items
{
    self = [super init];
    if (self) {
        
        self.itemNames = items;
    };
    return self;
}
-(void)setItemNames:(NSArray<NSString *> *)itemsName{
    _itemNames = itemsName;
    _sectionLable.text = _itemNames[0];
    _currentTag = 0;
    [_listView reloadData];
}

-(NSArray<NSNumber *> *)itemTags{
    
    if (_itemTags == nil || _itemTags.count != _itemNames.count) {
        NSMutableArray* arry = [[NSMutableArray alloc]initWithCapacity:_itemNames.count];
        for (int i = 0; i< _itemNames.count; i++) {
            [arry addObject:@(i)];
        }
        _itemTags = arry;
    }
    return _itemTags;
}

-(void)setItemTags:(NSArray<NSNumber *> *)itemTags{
    _itemTags = itemTags;
    if (itemTags.count > 0) {
        _currentTag = [itemTags[0]intValue];
    }
}


-(void)setFrame:(CGRect)frame{
    if (CGRectEqualToRect(frame, self.frame)) {
        return;
    }
    [super setFrame:frame];
    _sectionBtn.frame = self.bounds;
    _cellHeight = frame.size.height;
    CGRect rect = frame;
    rect.origin.y = CGRectGetMaxY(frame);
    rect.size.height = 0;
    _listView.frame = rect;
    _listView.rowHeight = _cellHeight;
    
    [self updateAccessViewFrame];
}
-(UIView *)alphaBackGroundView{
    if(_alphaBackGroundView == nil){
        _alphaBackGroundView = [[UIView alloc]initWithFrame:[UIScreen mainScreen].bounds];
        _alphaBackGroundView.backgroundColor = [UIColor blackColor];
        _alphaBackGroundView.alpha = 0.5;

    }
    return _alphaBackGroundView;
}
-(UIButton *)backGroundView{
    if (_backGroundView == nil) {
        _backGroundView = [[UIButton alloc]initWithFrame:[UIScreen mainScreen].bounds];
        [_backGroundView addTarget:self action:@selector(backGroundClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backGroundView;
}
-(void)backGroundClick:(UIButton*)btn{
    [self selectBtn:_sectionBtn];
}
-(void)selectTag:(NSInteger)currentTag{
    if (_currentTag != currentTag) {
        _currentTag = currentTag;
        for (int i = 0; i < self.itemTags.count; i++) {
            if ([_itemTags[i] integerValue] == _currentTag) {
                _sectionLable.text = _itemNames[i];
                NSIndexPath* indexpath = [NSIndexPath indexPathForRow:i inSection:0];
                [_listView selectRowAtIndexPath:indexpath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
    
    }
}
-(void)setAccessView:(UIView *)accessView{
    if (accessView == _accessView) {
        return;
    }
    _accessView = accessView;
    [_accessView setContentMode:UIViewContentModeScaleAspectFit];
    [_sectionBtn addSubview:accessView];
    [self updateAccessViewFrame];
}
-(void)updateAccessViewFrame{
    if (!self.accessView) {
        _sectionLable.frame = _sectionBtn.bounds;

    }else{
        
        CGRect rect ;
        rect.size.width = self.frame.size.height *0.6;
        rect.size.height = rect.size.width;
        rect.origin.y = (self.frame.size.height - rect.size.height) * 0.5;
        rect.origin.x = self.frame.size.width - rect.size.width - rect.origin.y;
        _accessView.frame = rect;
        
        rect.origin = CGPointZero;
        rect.size = CGSizeMake(_sectionBtn.bounds.size.width - rect.size.width, _sectionBtn.bounds.size.height);
        _sectionLable.frame = rect;
    }

}

-(void)open:(BOOL)isOpen{
    _isOpen = isOpen;
    if (_sectionBtn.selected != isOpen) {
        [self selectBtn:_sectionBtn];
    }
}

-(BOOL)isOpen{
    return _sectionBtn.selected;
}

-(BOOL)selectBtn:(UIButton*)btn{
    btn.selected = !btn.selected;
    if([self.PullDownViewDelegate respondsToSelector:@selector(GJPullDownView:shouldWillChangeToOpen:)]){
        if(![self.PullDownViewDelegate GJPullDownView:self shouldWillChangeToOpen:btn.selected]){
            btn.selected = !btn.selected;
            return NO;
        };
    }
    if (btn.isSelected) {
        [self open];
    }else{
        [self close];
       
    }
    return YES;
}
-(void)open{
    __block CGRect rect = self.frame;
    switch (_listViewShowType) {
        case ListViewShowModel:
        {
            rect = [self getInTopSuperViewFrameWithView:self];
            CGRect r = rect;
            r.origin.y += r.size.height;
            r.size.height = 0;
            _listView.frame = r;
            [[[UIApplication sharedApplication] keyWindow] addSubview:self.alphaBackGroundView];
            [[[UIApplication sharedApplication] keyWindow] addSubview:self.backGroundView];
            [self.backGroundView addSubview:_listView];
        }
            break;
        case ListViewShowInSelf:
        {
            CGRect r = self.bounds;
            r.origin.y = r.size.height;
            r.size.height = 0;
            _listView.frame = r;
            [self addSubview:_listView];
        }
            break;
        case ListViewShowInSuperView:
        {
            CGRect r = self.frame;
            r.origin.y += r.size.height;
            r.size.height = 0;
            _listView.frame = r;
            [self.superview addSubview:_listView];
            
        }
            break;
            
        default:
            break;
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        if (_showMaxCellCount >0) {
            rect.size.height = (_itemNames.count < _showMaxCellCount? _itemNames.count:_showMaxCellCount) * _cellHeight;
        }else{
            rect.size.height = _itemNames.count * _cellHeight;
        }
        switch (_listViewShowType) {
            case ListViewShowModel:
            {
                rect.origin.y += self.bounds.size.height;
                _listView.frame = rect;
            }
                break;
            case ListViewShowInSelf:
            {
                rect.origin.x = 0;
                rect.origin.y = self.frame.size.height;
                _listView.frame = rect;
 
                CGRect r = self.frame;
                r.size.height += rect.size.height;
                super.frame = r;
            }
                
                break;
            case ListViewShowInSuperView:
            {
                rect.origin.y = CGRectGetMaxY(self.frame);
                _listView.frame = rect;
            }
                break;
                
            default:
                break;
        }
        
        if (self.accessViewType == AccessViewTypeArrow) {
            self.accessView.transform = CGAffineTransformMakeRotation(M_PI);
        }
        
    }completion:^(BOOL finished) {
        if([self.PullDownViewDelegate respondsToSelector:@selector(GJPullDownView:didChangeToOpen:)]){
            [self.PullDownViewDelegate GJPullDownView:self didChangeToOpen:YES];
        }
        
    }];
}
-(void)close{
    [UIView animateWithDuration:0.2 animations:^{
        __block CGRect rect = _listView.frame;
        switch (_listViewShowType) {
            case ListViewShowModel:
            {
                rect.size.height = 0;
                _listView.frame = rect;
            }
                break;
            case ListViewShowInSelf:
            {
                rect.size.height = 0;
                _listView.frame = rect;
                
                rect = self.frame;
                rect.size.height = _sectionBtn.bounds.size.height;
                super.frame = rect;
            }
                break;
            case ListViewShowInSuperView:
            {
                rect.size.height = 0;
                _listView.frame = rect;
            }
                break;
                
            default:
                break;
        }
        
        if (self.accessViewType == AccessViewTypeArrow) {
            self.accessView = self.arrow;
            self.accessView.transform = CGAffineTransformIdentity;
        }
    }completion:^(BOOL finished) {
        if([self.PullDownViewDelegate respondsToSelector:@selector(GJPullDownView:didChangeToOpen:)]){
            [self.PullDownViewDelegate GJPullDownView:self didChangeToOpen:NO];
        }
        [_listView removeFromSuperview];
        if (_listViewShowType == ListViewShowModel) {
            [self.backGroundView removeFromSuperview];
            [self.alphaBackGroundView removeFromSuperview];
        }
    }];
}

-(CGRect)getInTopSuperViewFrameWithView:(UIView*)view{
    CGRect rect = view.frame;
    id superView = view.superview;
    while ([superView isKindOfClass:[UIView class]]) {
        rect.origin.x += ((UIView*)superView).frame.origin.x;
        rect.origin.y += ((UIView*)superView).frame.origin.y;
        superView = ((UIView*)superView).superview;
    }
    return rect;
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"GJPullDownViewCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"GJPullDownViewCell"];
        [cell.textLabel setFont:_listTextFont];
        cell.textLabel.textAlignment = self.listAlignment;
        cell.backgroundColor = [UIColor clearColor];
    }
    cell.textLabel.text = _itemNames[indexPath.row];
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _itemNames.count;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    _sectionLable.text =_itemNames[indexPath.row];
    _currentTag = [self.itemTags[indexPath.row] integerValue];
    if([self selectBtn:_sectionBtn]){
        if ([self.PullDownViewDelegate respondsToSelector:@selector(GJPullDownView:selectIndex:)]) {
            [self.PullDownViewDelegate GJPullDownView:self selectIndex:indexPath.row];
        }
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
