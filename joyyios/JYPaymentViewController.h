//
//  JYPaymentViewController.h
//  joyyios
//
//  Created by Ping Yang on 6/18/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <CardIO/CardIO.h>

#import "JYBaseViewController.h"

@class JYPaymentViewController;

@protocol JYPaymentViewControllerDelegate <NSObject>

- (void)viewControllerDidCreateToken:(NSString *)token;
- (void)viewControllerDidFinish:(JYPaymentViewController *)controller;

@end



@interface JYPaymentViewController : JYBaseViewController <CardIOPaymentViewControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, weak) id<JYPaymentViewControllerDelegate> delegate;

@end
