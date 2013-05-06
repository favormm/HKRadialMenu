//
//  HKGestureRecognizer.m
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

#import "HKRadialGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

static CGPoint CGPointSubtract(CGPoint p1, CGPoint p2)
{
    CGFloat dx = p1.x - p2.x;
    CGFloat dy = p1.y - p2.y;

    return CGPointMake(dx, dy);
}

static CGFloat CGPointLengthSq(CGPoint p)
{
    return (p.x * p.x + p.y * p.y);
}

static CGFloat CGPointLength(CGPoint p)
{
    return sqrt(CGPointLengthSq(p));
}

static CGFloat CGPointDistanceSq(CGPoint p1, CGPoint p2)
{
    return CGPointLengthSq(CGPointSubtract(p1, p2));
}

static CGFloat CGPointDistance(CGPoint p1, CGPoint p2)
{
    return CGPointLength(CGPointSubtract(p1, p2));
}

static CGPoint CGPointNormalize(CGPoint p)
{
    CGFloat length = CGPointLength(p);

    return CGPointMake(p.x / length, p.y / length);
}

static CGFloat CGFloatNormalizeAngle(CGFloat angle)
{
    if (angle < .0f)
    {
        angle += 2 * M_PI;
    }
    if (angle > 2 * M_PI)
    {
        angle = fmod(angle, 2 * M_PI);
    }

    return angle;
}


@interface HKRadialGestureRecognizer ()

@property (nonatomic) NSInteger closestAngleIndex;
@property (nonatomic) CGFloat innerRadiusSq;
@property (nonatomic) CGFloat outerRadiusSq;

@end

@implementation HKRadialGestureRecognizer

- (void)reset
{
    [super reset];
    self.closestAngleIndex = NSNotFound;
}

- (NSArray *)angles
{
    if (!_angles)
        _angles = @[];

    return _angles;
}

- (void)setInnerRadius:(CGFloat)innerRadius
{
    if (_innerRadius == innerRadius)
        return;

    _innerRadius = innerRadius;
    self.innerRadiusSq = innerRadius * innerRadius;
}

- (void)setOuterRadius:(CGFloat)outerRadius
{
    if (_outerRadius == outerRadius)
        return;

    _outerRadius = outerRadius;
    self.outerRadiusSq = outerRadius * outerRadius;
}

- (void)setClosestAngleIndex:(NSInteger)closestAngleIndex
{
    if (_closestAngleIndex == closestAngleIndex)
        return;

    _closestAngleIndex = closestAngleIndex;
    self.state = UIGestureRecognizerStateChanged;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    CGPoint tapPoint = [touch locationInView:self.view];
    CGRect viewFrame = self.view.frame;
    CGPoint viewCenter = CGPointMake(viewFrame.size.width * .5, viewFrame.size.height * .5);
    CGFloat distanceSq = CGPointDistanceSq(viewCenter, tapPoint);
    if (distanceSq < self.innerRadiusSq)
    {
        _closestAngleIndex = -1;
        self.state = UIGestureRecognizerStateBegan;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    CGPoint tapPoint = [touch locationInView:self.view];
    CGRect viewFrame = self.view.frame;
    CGPoint viewCenter = CGPointMake(viewFrame.size.width * .5, viewFrame.size.height * .5);
    CGPoint vector = CGPointSubtract(tapPoint, viewCenter);
    CGFloat distanceSq = CGPointLengthSq(vector);
    vector = CGPointNormalize(vector);

    if (distanceSq > self.outerRadiusSq)
    {
        self.closestAngleIndex = NSNotFound;
    }
    else if (distanceSq > self.innerRadiusSq)
    {
        CGFloat currentAngle = CGFloatNormalizeAngle(atan2(vector.y, vector.x));
        CGFloat smallestDelta = FLT_MAX;
        NSInteger closestAngleIndex = NSNotFound;
        NSInteger i = 0;
        for (NSNumber *angle in self.angles)
        {
            CGFloat delta = fabs(currentAngle - CGFloatNormalizeAngle(angle.floatValue));
            if (delta < smallestDelta)
            {
                smallestDelta = delta;
                closestAngleIndex = i;
            }

            ++i;
        }
        self.closestAngleIndex = closestAngleIndex;
    }
    else
    {
        self.closestAngleIndex = -1;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    CGPoint tapPoint = [touch locationInView:self.view];
    CGRect viewFrame = self.view.frame;
    CGPoint viewCenter = CGPointMake(viewFrame.size.width * .5, viewFrame.size.height * .5);
    CGFloat distanceSq = CGPointDistanceSq(viewCenter, tapPoint);

    if (distanceSq > self.outerRadiusSq)
    {
        self.state = UIGestureRecognizerStateCancelled;
    }
    else if (distanceSq > self.innerRadiusSq)
    {
        self.state = UIGestureRecognizerStateEnded;
    }
    else
    {
        self.state = UIGestureRecognizerStateEnded;
    }
}

@end
