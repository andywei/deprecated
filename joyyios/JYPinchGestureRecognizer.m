//
//  JYPinchGestureRecognizer.m
//  joyyios
//
//  Created by Ping Yang on 4/2/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYPinchGestureRecognizer.h"

@interface JYPinchGestureRecognizer ()

@property(nonatomic, weak) MKMapView *mapView;
@property(nonatomic) MKCoordinateRegion originalRegion;
@property(nonatomic) double lastScale;

@end

@implementation JYPinchGestureRecognizer

- (id)initWithMapView:(MKMapView *)mapView
{
    if (mapView == nil)
    {
        [NSException raise:NSInvalidArgumentException format:@"mapView cannot be nil."];
    }

    if ((self = [super initWithTarget:self action:@selector(_handlePinchGesture:)]))
    {
        self.mapView = mapView;
    }

    return self;
}

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    return NO;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
    {
        return YES;
    }
    return NO;
}

- (void)_handlePinchGesture:(JYPinchGestureRecognizer *)sender
{
    if ([sender numberOfTouches] < 2)
    {
        return;
    }

    if (sender.state == UIGestureRecognizerStateBegan)
    {
        self.originalRegion = sender.mapView.region;
        self.lastScale = 1.0;
    }

    double scale = (double)sender.scale;
    self.lastScale = scale;
    double latdelta = self.originalRegion.span.latitudeDelta / scale;
    double londelta = self.originalRegion.span.longitudeDelta / scale;

    latdelta = fmin(80.0f, latdelta);
    londelta = fmin(80.0f, londelta);

    NSLog(@"scale = %.20f", scale);
    NSLog(@"latdelta = %.20f", latdelta);

    MKCoordinateSpan span = MKCoordinateSpanMake(latdelta, londelta);

    MKCoordinateRegion newRegion = MKCoordinateRegionMake(self.originalRegion.center, span);
    [sender.mapView setRegion:newRegion animated:NO];
}

@end
