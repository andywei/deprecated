//
//  JYOrderCreateFormViewController.m
//  joyyios
//
//  Created by Ping Yang on 4/3/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

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
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"time" rowType:XLFormRowDescriptorTypeDateTime title:NSLocalizedString(@"When should it start?", nil)];
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
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"description" rowType:XLFormRowDescriptorTypeTextViewRestricted title:@"300"];
    [row.cellConfigAtConfigure setObject:NSLocalizedString(@"More details", nil) forKey:@"textView.placeholder"];
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
    row.value = [JYOrder currentOrder].startAddress;
    [row.cellConfig setObject:ClearColor forKey:@"backgroundColor"];
    [section addFormRow:row];

    if ([JYOrder currentOrder].endAddress)
    {
        row = [XLFormRowDescriptor formRowDescriptorWithTag:@"endAddress" rowType:XLFormRowDescriptorTypeInfo title:NSLocalizedString(@"To:", nil)];
        row.value = [JYOrder currentOrder].endAddress;
        [row.cellConfig setObject:ClearColor forKey:@"backgroundColor"];
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

- (void)_submitButtonPressed
{

}

@end
