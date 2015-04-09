//
//  JYPlacesViewController.h
//  joyyios
//
//  Created by Ping Yang on 4/8/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

@import MapKit;

@interface JYPlacesViewController : UIViewController <UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic) CLLocationCoordinate2D searchCenter;
@property (nonatomic) UIImage *searchBarImage;

@end
