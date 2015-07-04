//
//  JYOrderMapViewController.h
//  joyyios
//
//  Created by Ping Yang on 4/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYMapDashBoardView.h"
#import "JYPlacesViewController.h"

@import MapKit;

@interface JYOrderMapViewController : UIViewController <JYMapDashBoardViewDelegate, JYPlacesViewControllerDelegate, MKMapViewDelegate, UIGestureRecognizerDelegate>

@end
