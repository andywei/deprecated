//
//  JYOrderDetailsViewController.m
//  joyyios
//
//  Created by Ping Yang on 4/3/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <RKDropdownAlert/RKDropdownAlert.h>
#import <XLForm/XLForm.h>

#import "JYButton.h"
#import "JYInvite.h"
#import "JYOrderDetailsViewController.h"
#import "JYPriceTextFieldCell.h"
#import "JYRestrictedTextViewCell.h"
#import "JYUser.h"

@interface JYOrderDetailsViewController ()

@end

@implementation JYOrderDetailsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIBarButtonItem *barButton =
    [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Submit", nil) style:UIBarButtonItemStylePlain target:self action:@selector(_submit)];
    self.navigationItem.rightBarButtonItem = barButton;

    [self _createForm];
    [self _createSubmitButton];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self _saveOrder];
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)_createForm
{
    XLFormDescriptor *form;
    XLFormSectionDescriptor *section;
    XLFormRowDescriptor *row;

    form = [XLFormDescriptor formDescriptorWithTitle:NSLocalizedString(@"Details", nil)];
    form.assignFirstResponderOnShow = YES;

    // Date and Time
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"startTime" rowType:XLFormRowDescriptorTypeDateTime title:NSLocalizedString(@"When should it start?", nil)];
    [row.cellConfigAtConfigure setObject:[NSDate date] forKey:@"minimumDate"];
    [row.cellConfigAtConfigure setObject:@(15) forKey:@"minuteInterval"];
    row.value = [NSDate dateWithTimeIntervalSinceNow:k15Minutes];;
    [section addFormRow:row];

    // Price
    section = [XLFormSectionDescriptor formSectionWithTitle:NSLocalizedString(@"How many US Dollars you like to pay?", nil)];
    [form addFormSection:section];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"price" rowType:XLFormRowDescriptorTypePrice title:NSLocalizedString(@"", nil)];
    [row.cellConfig setObject:[UIFont boldSystemFontOfSize:23] forKey:@"textField.font"];
    [row.cellConfig setObject:FlatGreen forKey:@"textField.textColor"];
    [row.cellConfig setObject:@(NSTextAlignmentCenter) forKey:@"textField.textAlignment"];
    row.value = @"$";
    [section addFormRow:row];

    // Number of hours
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"hours" rowType:XLFormRowDescriptorTypeSelectorPickerView title:NSLocalizedString(@"Rooms", nil)];
    row.selectorOptions = @[[XLFormOptionsObject formOptionsObjectWithValue:@(0) displayText:@"1"],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(1) displayText:@"2"],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(2) displayText:@"3"],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(3) displayText:@"4"],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(4) displayText:@"5"],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(5) displayText:@"6"],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(6) displayText:@"7"],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(7) displayText:@"8"],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(8) displayText:@"9"]
                            ];
    row.value = [XLFormOptionsObject formOptionsObjectWithValue:@(2) displayText:@"3"];
    [section addFormRow:row];


    // Note
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    // Use the title to pass the leng limit value 300. 
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"note" rowType:XLFormRowDescriptorTypeTextViewRestricted title:@"300"];
    [row.cellConfigAtConfigure setObject:NSLocalizedString(@"More details", nil) forKey:@"textView.placeholder"];
    row.value = [JYInvite currentInvite].note;
    [section addFormRow:row];

    // Address
    NSString *title = NSLocalizedString(@"Addr:", nil);
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"address" rowType:XLFormRowDescriptorTypeInfo title:title];
    [row.cellConfig setObject:ClearColor forKey:@"backgroundColor"];
    row.value = [JYInvite currentInvite].address;
    [section addFormRow:row];

    self.form = form;
}

- (void)_createSubmitButton
{
    JYButton *submitButton = [JYButton button];
    submitButton.y = CGRectGetHeight(self.view.frame) - kButtonDefaultHeight;
    submitButton.textLabel.text = NSLocalizedString(@"Submit", nil);

    [submitButton addTarget:self action:@selector(_submit) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:submitButton];
}

- (void)_saveOrder
{
    // note
    id note = [self.formValues objectForKey:@"note"];
    [JYInvite currentInvite].note = [note isKindOfClass:[NSNull class]] ? @"(ᵔᴥᵔ)" : [self.formValues valueForKey:@"note"];

    // startTime
    NSDate *startTime = (NSDate *)[self.formValues objectForKey:@"startTime"];
    [JYInvite currentInvite].startTime = (NSUInteger)startTime.timeIntervalSinceReferenceDate;

    // price
    NSString *priceString = [[self.formValues valueForKey:@"price"] substringFromIndex:1];
    NSUInteger priceInDollars = priceString? [priceString  unsignedIntegerValue]: 0;
    NSUInteger priceInCents = priceInDollars * 100;
    [JYInvite currentInvite].price = priceInCents;

    // category
//    [JYOrder currentInvite].category = userChosedCategory;

    // title
    NSString *serviceName = [JYInvite currentInvite].categoryName;
    XLFormOptionsObject *hoursObj = [self.formValues valueForKey:@"hours"];

    if (hoursObj)
    {
        NSInteger hours = [hoursObj.formValue integerValue] + 1;
        NSString *localizedString = NSLocalizedString(([NSString stringWithFormat:@" for %ld hours", (long)hours]), nil);
        [JYInvite currentInvite].title = [NSString stringWithFormat:@"%@%@", serviceName, localizedString];
    }
    else
    {
        [JYInvite currentInvite].title = serviceName;
    }
}

- (void)_submit
{
    [self _saveOrder];
    [self _submitOrder];
}

#pragma mark - Network

- (void)_submitOrder
{
    NSDictionary *parameters = [[JYInvite currentInvite] httpParameters];
    NSLog(@"parameters = %@", parameters);

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"orders"];

    [KVNProgress show];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager POST:url
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
//              NSLog(@"OrderCreate Success responseObject: %@", responseObject);

              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
              [KVNProgress showSuccessWithStatus:NSLocalizedString(@"The Order Created!", nil)];

              // switch to orders nearby view and quit order creating process
              // The sequence of below 3 steps must not be changed
              [weakSelf.tabBarController setSelectedIndex:1];
              [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidCreateOrder object:nil];
              [weakSelf.navigationController popToRootViewControllerAnimated:NO];
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {

              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
              [KVNProgress dismiss];

              NSString *errorMessage = NSLocalizedString(@"Can't create order due to network failure, please retry later", nil);
              [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
                             message:errorMessage
                     backgroundColor:FlatYellow
                           textColor:FlatBlack
                                time:5];

          }
     ];
}

@end
