//
//  JYPanGestureRecognizer.m
//  joyyios
//
//  Created by Ping Yang on 4/2/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYPanGestureRecognizer.h"
#import "JYPinchGestureRecognizer.h"

@interface JYPanGestureRecognizer ()
@property(nonatomic, weak) MKMapView *mapView;
@end

@implementation JYPanGestureRecognizer

- (id)initWithMapView:(MKMapView *)mapView
{
    if (mapView == nil)
    {
        [NSException raise:NSInvalidArgumentException format:@"mapView cannot be nil."];
    }

    if ((self = [super initWithTarget:self action:@selector(_handlePanGesture:)]))
    {
        self.mapView = mapView;
    }

    return self;
}

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]])
    {
        return YES;
    }
    return NO;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    return NO;
}

- (void)_handlePanGesture:(JYPanGestureRecognizer *)sender
{
    if (!sender.mapView)
    {
        return;
    }

    if (sender.state == UIGestureRecognizerStateBegan)
    {
        if (sender.delegate && [sender.delegate respondsToSelector:@selector(panGestureBegin)])
        {
            [sender.delegate panGestureBegin];
        }
    }
    else if (sender.state == UIGestureRecognizerStateChanged)
    {
        // Do nothing. The mapview has scroll enabled and will handle scrolling by itself.
    }
    else
    {
        if (sender.delegate && [sender.delegate respondsToSelector:@selector(panGestureEnd)])
        {
            [sender.delegate panGestureEnd];
        }
    }
}

@end
