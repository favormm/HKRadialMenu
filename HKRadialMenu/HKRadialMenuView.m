//
//  HKRadialMenuView.m
//  HKRadialMenu
//
//  Copyright (c) 2013, Panos Baroudjian.
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.

#import "HKRadialMenuView.h"
#import "HKRadialMenuItemView.h"

#define TWO_PI M_PI * 2.0f

static const float k2Pi = TWO_PI;

@interface HKRadialMenuView ()

@property (nonatomic) BOOL itemsVisible;
@property (nonatomic) BOOL needsRelayout;
@property (nonatomic) BOOL needsReloadData;
@property (nonatomic) NSArray *items;
@property (nonatomic) UIView *centerView;

- (void)defaultInit;
- (void)onOrientationChanged:(NSNotification *)notification;
- (void)createCenterView;
- (void)createItems;
- (void)centerViewTapped:(UITapGestureRecognizer *)tapRecognizer;

- (UITapGestureRecognizer *)createGestureRecognizerForView:(UIView *)view
                                              withSelector:(SEL)selector;
- (void)recenterView:(HKRadialMenuItemView *)itemView;

+ (CGFloat)normalizeAngle:(CGFloat)angle;

@end

@implementation HKRadialMenuView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self defaultInit];
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self defaultInit];
    }

    return self;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [self defaultInit];
    }

    return self;
}

- (void)defaultInit
{
    CGFloat start = 0;
    CGFloat end = k2Pi;
    self.angleRange = CGPointMake(start, end);
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onOrientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:[UIDevice currentDevice]];
}

- (void)onOrientationChanged:(NSNotification *)notification
{
    self.needsRelayout = self.itemsVisible;
    [self hideItemsAnimated:NO];
}

+ (CGFloat)normalizeAngle:(CGFloat)angle
{
    if (angle < .0f)
    {
        angle += k2Pi;
    }
    if (angle > k2Pi)
    {
        angle = fmod(angle, k2Pi);
    }

    return angle;
}

- (void)setAngleRange:(CGPoint)angleRange
{
    angleRange.x = [HKRadialMenuView normalizeAngle:angleRange.x];
    angleRange.y = [HKRadialMenuView normalizeAngle:angleRange.y];
    
    if (CGPointEqualToPoint(angleRange, _angleRange))
        return;

    _angleRange = angleRange;
    if (self.itemsVisible)
        [self revealItemsAnimated:YES];
}

- (UITapGestureRecognizer *)createGestureRecognizerForView:(UIView *)view withSelector:(SEL)selector
{
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:selector];
    recognizer.numberOfTouchesRequired = 1;
    recognizer.numberOfTapsRequired = 1;
    [view addGestureRecognizer:recognizer];

    return recognizer;
}

- (void)recenterView:(HKRadialMenuItemView *)itemView
{
    [itemView recenterLayout];
    CGRect frame = itemView.frame;
    CGPoint center = self.center;
    frame.origin.x = center.x - frame.size.width * .5;
    frame.origin.y = center.y - frame.size.height * .5;
    itemView.frame = frame;
}

- (void)createCenterView
{
    if (self.centerView)
    {
        [self.centerView removeFromSuperview];
        self.centerView = nil;
    }

    HKRadialMenuItemView *centerView = [self.dataSource centerItemViewForRadialMenuView:self];
    if (centerView)
    {
        [self recenterView:centerView];
        [self createGestureRecognizerForView:centerView
                                withSelector:@selector(centerViewTapped:)];
        [self addSubview:centerView];
        self.centerView = centerView;
    }
}

- (void)centerViewTapped:(UITapGestureRecognizer *)tapRecognizer
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(radialMenuViewDidSelectCenterView:)])
    {
        [self.delegate radialMenuViewDidSelectCenterView:self];
    }

    if (self.itemsVisible)
        [self hideItemsAnimated:YES];
    else
        [self revealItemsAnimated:YES];
}

- (void)createItems
{
    if (self.items)
    {
        for (NSUInteger i = 0; i < self.items.count; ++i)
        {
            UIView *itemView = [self.items objectAtIndex:i];
            [itemView removeFromSuperview];
        }

        self.items = nil;
    }

    NSUInteger nbItems = 1;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(numberOfItemsInRadialMenuView:)])
        nbItems = [self.dataSource numberOfItemsInRadialMenuView:self];
    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:nbItems];
    for (NSUInteger i = 0; i < nbItems; ++i)
    {
        HKRadialMenuItemView *itemView = [self.dataSource itemViewInRadialMenuView:self
                                                                           atIndex:i];
        if (itemView)
        {
            itemView.alpha = .0;
            [self recenterView:itemView];
            [self createGestureRecognizerForView:itemView
                                    withSelector:@selector(itemViewTapped:)];
            [items addObject:itemView];
            [self addSubview:itemView];
        }
    }
    
    self.items = items;
    self.itemsVisible = NO;
}

- (void)itemViewTapped:(UITapGestureRecognizer *)tapRecognizer
{
    NSUInteger index = [self.items indexOfObject:tapRecognizer.view];
    if (index != NSNotFound)
    {
        [self.delegate radialMenuView:self didSelectItemAtIndex:index];
    }
}

- (void)reloadData
{
    [self createCenterView];
    [self createItems];
    self.needsReloadData = NO;
}

- (void)revealItemsAnimated:(BOOL)animated
{
    NSUInteger nbItems = self.items.count;
    if (!nbItems)
        return;

    BOOL dynamicAngles = self.delegate && [self.delegate respondsToSelector:@selector(angleForItemViewInRadialMenuView:atIndex:)];
    CGFloat deltaAngle = (self.angleRange.y - self.angleRange.x) / (CGFloat)nbItems;
    CGFloat angle = self.angleRange.x;
    for (NSUInteger i = 0; i < nbItems; ++i)
    {
        if (dynamicAngles)
            angle = [self.delegate angleForItemViewInRadialMenuView:self atIndex:i];
        CGFloat distance = [self.delegate distanceForItemInRadialMenuView:self
                                                                  atIndex:i];
        BOOL rotate = [self.delegate rotateItemInRadialMenuView:self
                                                        atIndex:i];
        CGAffineTransform transform = CGAffineTransformIdentity;
        if (rotate)
            transform = CGAffineTransformRotate(transform, -angle);
        transform.tx = distance;
        transform = CGAffineTransformConcat(transform, CGAffineTransformMakeRotation(angle));
        UIView *itemView = [self.items objectAtIndex:i];
        if (animated)
        {
            [UIView animateWithDuration:self.animationDuration
                                  delay:i * self.delayBetweenAnimations
                                options:UIViewAnimationOptionCurveEaseOut |
                                        UIViewAnimationOptionBeginFromCurrentState
                             animations:^(){
                                 itemView.alpha = 1.;
                                 itemView.transform = transform;
                             }
                             completion:nil];
        }
        else
        {
            itemView.alpha = 1.;
            itemView.transform = transform;
        }
        
        angle += deltaAngle;
    }
    
    self.itemsVisible = YES;
}

- (void)hideItemsAnimated:(BOOL)animated
{
    if (!self.itemsVisible)
        return;

    NSUInteger nbItems = [[self items] count];
    if (!nbItems)
        return;

    for (NSUInteger i = nbItems; i != 0; --i)
    {
        UIView *itemView = [self.items objectAtIndex:i - 1];
        if (animated)
        {
            [UIView animateWithDuration:self.animationDuration
                                  delay:(nbItems - i) * self.delayBetweenAnimations
                                options:UIViewAnimationOptionCurveEaseOut |
                                        UIViewAnimationOptionBeginFromCurrentState
                             animations:^(){
                                 itemView.alpha = 0.;
                                 itemView.transform = CGAffineTransformIdentity;
                             }
                             completion:nil];
        }
        else
        {
            itemView.alpha = 0.;
            itemView.transform = CGAffineTransformIdentity;
        }
    }
    
    self.itemsVisible = NO;
}

- (void)setDataSource:(id<HKRadialMenuViewDataSource>)dataSource
{
    if (dataSource == _dataSource)
        return;
    
    _dataSource = dataSource;
    self.needsReloadData = YES;
}

- (void)layoutSubviews
{
    if (self.needsReloadData)
    {
        [self reloadData];
    }

    [super layoutSubviews];
    
    if (self.needsRelayout)
    {
        [self revealItemsAnimated:NO];
        self.needsRelayout = NO;
    }
}

@end
