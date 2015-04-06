//
//  JYSignBaseViewController.m
//  joyyios
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYAutoCompleteDataSource.h"
#import "JYButton.h"
#import "JYFloatLabeledTextField.h"
#import "JYSignBaseViewController.h"

@interface JYSignBaseViewController ()

@property(nonatomic, strong) UIView *partingLine;

@end

@implementation JYSignBaseViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.tintColor = JoyyBlue;
    self.navigationController.navigationBar.tintColor = JoyyBlue;

    [self _createEmailField];
    [self _createPartingLine];
    [self _createPasswordField];
    [self _createSignButton];

    [_emailField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchSignButton
{
    _signButton.selected = YES;
    [self signButtonTouched];
    _signButton.selected = NO;
}

- (void)signButtonTouched
{
    NSAssert(NO, @"The signButtonTouched method in the base clasee should never been called");
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _emailField)
    {
        [_emailField resignFirstResponder];
        [_passwordField becomeFirstResponder];
        return NO;
    }
    else if (textField == _passwordField)
    {
        [_passwordField resignFirstResponder];
        [self touchSignButton];
        return NO;
    }

    return YES;
}

#pragma mark - Private Methods

- (void)_createEmailField
{
    CGFloat y = kSignViewTopOffset;
    CGFloat width = CGRectGetWidth(self.view.frame) - 2 * kSignFieldMarginLeft;
    _emailField = [[JYFloatLabeledTextField alloc] initWithFrame:CGRectMake(kSignFieldMarginLeft, y, width, kSignFieldHeight)];

    _emailField.attributedPlaceholder =
        [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Email", nil) attributes:@{NSForegroundColorAttributeName : FlatGrayDark}];

    _emailField.autocompleteDataSource = [JYAutoCompleteDataSource sharedDataSource];
    _emailField.autocompleteType = JYAutoCompleteTypeEmail;
    _emailField.delegate = self;
    _emailField.floatingLabel.font = [UIFont systemFontOfSize:kSignFieldFloatingLabelFontSize];
    _emailField.font = [UIFont systemFontOfSize:kSignFieldFontSize];
    _emailField.keyboardType = UIKeyboardTypeEmailAddress;
    _emailField.returnKeyType = UIReturnKeyNext;

    [self.view addSubview:_emailField];
}

- (void)_createPartingLine
{
    CGFloat y = _emailField.frame.origin.y + _emailField.frame.size.height;
    CGFloat width = CGRectGetWidth(self.view.frame) - 2 * kSignFieldMarginLeft;
    _partingLine = [UIView new];
    _partingLine.frame = CGRectMake(kSignFieldMarginLeft, y, width, 1.0f);
    _partingLine.backgroundColor = [FlatGray colorWithAlphaComponent:0.3f];
    [self.view addSubview:_partingLine];
}

- (void)_createPasswordField
{
    CGFloat y = _partingLine.frame.origin.y + _partingLine.frame.size.height;
    CGFloat width = CGRectGetWidth(self.view.frame) - 2 * kSignFieldMarginLeft;
    _passwordField = [[JYFloatLabeledTextField alloc] initWithFrame:CGRectMake(kSignFieldMarginLeft, y, width, kSignFieldHeight)];
    _passwordField.attributedPlaceholder =
        [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Password", nil) attributes:@{NSForegroundColorAttributeName : FlatGray}];
    _passwordField.delegate = self;
    _passwordField.floatingLabel.font = [UIFont systemFontOfSize:kSignFieldFloatingLabelFontSize];
    _passwordField.font = [UIFont systemFontOfSize:kSignFieldFontSize];
    _passwordField.returnKeyType = UIReturnKeyDone;
    _passwordField.secureTextEntry = YES;

    [self.view addSubview:_passwordField];
}

- (void)_createSignButton
{
    CGFloat y = self.passwordField.frame.origin.y + self.passwordField.frame.size.height + kSignButtonMarginTop;
    CGFloat width = CGRectGetWidth(self.view.frame) - 2 * kSignFieldMarginLeft;
    CGRect signButtonFrame = CGRectMake(kSignFieldMarginLeft, y, width, kSignButtonHeight);

    _signButton = [[JYButton alloc] initWithFrame:signButtonFrame buttonStyle:JYButtonStyleDefault];
    _signButton.backgroundColor = ClearColor;
    _signButton.contentAnimateToColor = FlatGreen;
    _signButton.contentColor = FlatWhite;
    _signButton.cornerRadius = kButtonCornerRadius;
    _signButton.foregroundAnimateToColor = FlatWhite;
    _signButton.foregroundColor = FlatGreen;
    _signButton.textLabel.font = [UIFont boldSystemFontOfSize:kSignFieldFontSize];

    [self.view addSubview:_signButton];
}
@end
