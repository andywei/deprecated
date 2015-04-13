//
//  JYOrderCreateDetailsViewController.m
//  joyyios
//
//  Created by Ping Yang on 4/3/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "JYButton.h"
#import "JYOrder.h"
#import "JYOrderCreateDetailsViewController.h"
#import "JYPriceTextFieldCell.h"
#import "JYRestrictedTextViewCell.h"
#import "JYServiceCategory.h"
#import "XLForm.h"

@interface JYOrderCreateDetailsViewController ()

@end

@implementation JYOrderCreateDetailsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIBarButtonItem *barButton =
    [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Submit", nil) style:UIBarButtonItemStylePlain target:self action:@selector(_submitButtonPressed)];
    self.navigationItem.rightBarButtonItem = barButton;

    [self _createForm];
    [self _createSubmitButton];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self _saveOrder];
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
    row.value = [NSDate new];
    [section addFormRow:row];

    // Price
    section = [XLFormSectionDescriptor formSectionWithTitle:NSLocalizedString(@"How many US Dollars you like to pay?", nil)];
    [form addFormSection:section];
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"price" rowType:XLFormRowDescriptorTypePrice title:NSLocalizedString(@"", nil)];
    [row.cellConfig setObject:[UIFont systemFontOfSize:20] forKey:@"textField.font"];
    [row.cellConfig setObject:FlatGreen forKey:@"textField.textColor"];
    [row.cellConfig setObject:@(NSTextAlignmentCenter) forKey:@"textField.textAlignment"];
    row.value = @"$";
    [section addFormRow:row];

    // Number of rooms
    NSUInteger categoryIndex = [JYOrder currentOrder].categoryIndex;
    BOOL showRoomNumberField = (categoryIndex == JYServiceCategoryIndexCleaning || categoryIndex == JYServiceCategoryIndexMoving);

    if (showRoomNumberField)
    {
        section = [XLFormSectionDescriptor formSection];
        [form addFormSection:section];
        row = [XLFormRowDescriptor formRowDescriptorWithTag:@"rooms" rowType:XLFormRowDescriptorTypeSelectorPickerView title:NSLocalizedString(@"Rooms", nil)];
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
    }

    // Description
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    // Use the title to pass the leng limit value 300. 
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"note" rowType:XLFormRowDescriptorTypeTextViewRestricted title:@"300"];
    [row.cellConfigAtConfigure setObject:NSLocalizedString(@"More details", nil) forKey:@"textView.placeholder"];
    row.value = [JYOrder currentOrder].note;
    [section addFormRow:row];

    // Address
    // When the room number field is not shown, we have enough space to add a section head
    if (!showRoomNumberField)
    {
        section = [XLFormSectionDescriptor formSection];
        [form addFormSection:section];
    }

    NSString *title = ([JYOrder currentOrder].endAddress)? NSLocalizedString(@"From:", nil): NSLocalizedString(@"Addr:", nil);
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"startAddress" rowType:XLFormRowDescriptorTypeInfo title:title];
    [row.cellConfig setObject:ClearColor forKey:@"backgroundColor"];
    row.value = [JYOrder currentOrder].startAddress;
    [section addFormRow:row];

    if ([JYOrder currentOrder].endAddress)
    {
        row = [XLFormRowDescriptor formRowDescriptorWithTag:@"endAddress" rowType:XLFormRowDescriptorTypeInfo title:NSLocalizedString(@"To:", nil)];
        [row.cellConfig setObject:ClearColor forKey:@"backgroundColor"];
        row.value = [JYOrder currentOrder].endAddress;
        [section addFormRow:row];
    }

    self.form = form;
}

- (void)_createSubmitButton
{
    CGFloat y = CGRectGetHeight(self.view.frame) - kMapDashBoardSubmitButtonHeight;
    CGRect frame = CGRectMake(0, y, CGRectGetWidth(self.view.frame), kMapDashBoardSubmitButtonHeight);

    JYButton *submitButton = [[JYButton alloc] initWithFrame:frame buttonStyle:JYButtonStyleDefault];
    submitButton.backgroundColor = FlatWhite;
    submitButton.contentAnimateToColor = FlatGray;
    submitButton.contentColor = FlatWhite;
    submitButton.foregroundColor = FlatSkyBlue;
    submitButton.foregroundAnimateToColor = FlatWhite;
    submitButton.textLabel.font = [UIFont boldSystemFontOfSize:kSignFieldFontSize];
    submitButton.textLabel.text = NSLocalizedString(@"Submit", nil);

    [submitButton addTarget:self action:@selector(_submitButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:submitButton];
}

- (void)_saveOrder
{
    [JYOrder currentOrder].startAddress = [self.formValues valueForKey:@"startAddress"];
    [JYOrder currentOrder].endAddress = [self.formValues valueForKey:@"endAddress"];

    // note
    NSString *note = [self.formValues valueForKey:@"note"];
    [JYOrder currentOrder].note = note? @"": note;

    // startTime
    NSDate *startTime = (NSDate *)[self.formValues objectForKey:@"startTime"];
    [JYOrder currentOrder].startTime = (NSUInteger)startTime.timeIntervalSinceReferenceDate;

    // price
    NSString *priceString = [[self.formValues valueForKey:@"price"] substringFromIndex:1];
    [JYOrder currentOrder].price = priceString? [priceString  unsignedIntegerValue]: 0;

    // category
    NSUInteger index = [JYOrder currentOrder].categoryIndex;
    [JYOrder currentOrder].category = [JYServiceCategory categoryAtIndex:index];

    // title
    NSString *serviceName = [JYServiceCategory names][index];
    XLFormOptionsObject *roomsObj = [self.formValues valueForKey:@"rooms"];

    if (roomsObj)
    {
        NSString *roomsString = roomsObj.displayText;
        NSLog(@"roomsString = %@", roomsString);
        NSUInteger rooms = [roomsString unsignedIntegerValue];
        NSString *localizedString = NSLocalizedString(([NSString stringWithFormat:@" for %tu rooms", rooms]), nil);
        [JYOrder currentOrder].title = [NSString stringWithFormat:@"%@%@", serviceName, localizedString];
    }
    else
    {
        [JYOrder currentOrder].title = serviceName;
    }
}

- (void)_submitButtonPressed
{
    [self _saveOrder];
    NSDictionary *parameters = [[JYOrder currentOrder] httpParameters];
//    NSLog(@"%@", parameters);

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"orders"];

    [KVNProgress show];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    [manager POST:url
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"OrderCreate Success responseObject: %@", responseObject);

              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
              [KVNProgress dismiss];

              // do something
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"OrderCreate Error: %@", error);

              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
              [KVNProgress dismiss];

              NSString *errorMessage = nil;
              if (error.code == NSURLErrorBadServerResponse)
              {
                  errorMessage = NSLocalizedString(kErrorAuthenticationFailed, nil);
              }
              else
              {
                  errorMessage = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
              }

              [RKDropdownAlert title:NSLocalizedString(@"Something wrong ...", nil)
                             message:errorMessage
                     backgroundColor:FlatYellow
                           textColor:FlatBlack
                                time:5];
          }];

}

@end
