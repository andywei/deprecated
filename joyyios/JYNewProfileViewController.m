//
//  JYNewProfileViewController.m
//  joyyios
//
//  Created by Ping Yang on 9/20/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <AKPickerView/AKPickerView.h>
#import <RKDropdownAlert/RKDropdownAlert.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYAvatarCreator.h"
#import "JYButton.h"
#import "JYFilename.h"
#import "JYFloatLabeledTextField.h"
#import "JYNewProfileViewController.h"
#import "JYYRS.h"
#import "TGCameraColor.h"
#import "TGCameraViewController.h"
#import "UITextField+Joyy.h"

@interface JYNewProfileViewController () <AKPickerViewDataSource, AKPickerViewDelegate, JYAvatarCreatorDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) BOOL hasYobProvided;
@property (nonatomic) AKPickerView *sexPickerView;
@property (nonatomic) JYAvatarCreator *avatarCreator;
@property (nonatomic) JYButton *saveButton;
@property (nonatomic) JYButton *avatarButton;
@property (nonatomic) JYButton *photoButton;
@property (nonatomic) NSUInteger sex;
@property (nonatomic) TTTAttributedLabel *headerLabel;
@property (nonatomic) TTTAttributedLabel *sexLabel;
@property (nonatomic) UIImage *avatarImage;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) UITextField *yobTextField;
@property (nonatomic) UIView *avatarContainerView;
@end

static NSString *const kProfileCellIdentifier = @"profileCell";
const CGFloat kHeaderLabelHeight = 50;
const CGFloat kAvatarButtonHeight = 200;
const CGFloat kAvatarButtonWidth = kAvatarButtonHeight;

@implementation JYNewProfileViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Profile", nil);

    self.hasYobProvided = NO;
    self.avatarImage = nil;

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", nil) style:UIBarButtonItemStylePlain target:self action:@selector(_didTapSaveButton)];
    [self _enableButtons:NO];

    [self.view addSubview:self.tableView];
    [self.avatarCreator showOptions];
}

- (JYAvatarCreator *)avatarCreator
{
    if (!_avatarCreator)
    {
        _avatarCreator = [[JYAvatarCreator alloc] initWithViewController:self];
        _avatarCreator.delegate = self;
    }
    return _avatarCreator;
}

- (UITableView *)tableView
{
    if (!_tableView)
    {
        _tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = JoyyWhitePure;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.allowsSelection = NO;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kProfileCellIdentifier];
    }
    return _tableView;
}

- (JYButton *)saveButton
{
    if (!_saveButton)
    {
        JYButton *button = [JYButton button];
        button.textLabel.text = NSLocalizedString(@"Save", nil);
        button.enabled = NO;
        [button addTarget:self action:@selector(_didTapSaveButton) forControlEvents:UIControlEventTouchUpInside];
        _saveButton = button;
    }
    return _saveButton;
}

- (UIView *)avatarContainerView
{
    if (!_avatarContainerView)
    {
        _avatarContainerView = [[UIView alloc] initWithFrame:self.avatarButton.frame];
    }
    return _avatarContainerView;
}

- (JYButton *)avatarButton
{
    if (!_avatarButton)
    {
        CGRect frame = CGRectMake(0, 0, kAvatarButtonWidth, kAvatarButtonHeight);
        UIImage *image = image = [UIImage imageNamed:@"add"];
        JYButton *button = [JYButton iconButtonWithFrame:frame icon:image color:JoyyWhite];
        button.imageView.contentMode = UIViewContentModeCenter;
        button.imageView.layer.borderWidth = 2;
        button.imageView.layer.borderColor = JoyyWhite.CGColor;
        button.imageView.layer.cornerRadius = 4;
        button.imageView.clipsToBounds = YES;

        [button addTarget:self action:@selector(_didTapAvatarButton) forControlEvents:UIControlEventTouchUpInside];
        _avatarButton = button;
    }
    return _avatarButton;
}

- (JYButton *)photoButton
{
    if (!_photoButton)
    {
        CGRect frame = self.avatarButton.frame;

        JYButton *button = [JYButton buttonWithFrame:frame buttonStyle:JYButtonStyleCentralImage shouldMaskImage:NO];
        button.imageView.contentMode = UIViewContentModeScaleAspectFill;
        button.imageView.layer.cornerRadius = 4;
        button.imageView.clipsToBounds = YES;

        [button addTarget:self action:@selector(_didTapAvatarButton) forControlEvents:UIControlEventTouchUpInside];
        _photoButton = button;
    }
    return _photoButton;
}

- (TTTAttributedLabel *)headerLabel
{
    if (!_headerLabel)
    {
        CGFloat width = SCREEN_WIDTH - kMarginLeft - kMarginRight;
        CGRect frame = CGRectMake(kMarginLeft, 0, width, kHeaderLabelHeight);
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:frame];
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.font = [UIFont systemFontOfSize:15];
        label.text = NSLocalizedString(@"Create your public profile", nil);
        label.textAlignment = NSTextAlignmentCenter;

        _headerLabel = label;
    }
    return _headerLabel;
}

- (TTTAttributedLabel *)sexLabel
{
    if (!_sexLabel)
    {
        CGRect frame = CGRectMake(kMarginLeft, 0, 100, kCellHeight);
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:frame];
        label.font = [UIFont systemFontOfSize:16];
        label.textAlignment = NSTextAlignmentLeft;
        label.text = NSLocalizedString(@"Gender", nil);
        _sexLabel = label;
    }
    return _sexLabel;
}

- (AKPickerView *)sexPickerView
{
    if (!_sexPickerView)
    {
        CGRect frame = CGRectMake(0, 0, 120, kCellHeight);
        _sexPickerView = [[AKPickerView alloc] initWithFrame:frame];
        _sexPickerView.dataSource = self;
        _sexPickerView.delegate = self;
        [_sexPickerView reloadData];

        // Selecte the item in the middle, which makes user realize this is a picker
        self.sex = 1;
        [_sexPickerView selectItem:self.sex animated:NO];
    }
    return _sexPickerView;
}

- (UITextField *)yobTextField
{
    if (!_yobTextField)
    {
        CGFloat width = SCREEN_WIDTH - kMarginLeft - kMarginRight;
        CGRect frame = CGRectMake(0, 0, width, kCellHeight);

        JYFloatLabeledTextField *textField = [[JYFloatLabeledTextField alloc] initWithFrame:frame];
        textField.attributedPlaceholder =
        [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Year of Birth", nil) attributes:@{NSForegroundColorAttributeName : JoyyGray}];
        textField.delegate = self;
        textField.floatingLabel.font = [UIFont systemFontOfSize:11];
        textField.font = [UIFont systemFontOfSize:18];
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.returnKeyType = UIReturnKeyDone;

        _yobTextField = textField;
    }
    return _yobTextField;
}

- (void)_enableButtons:(BOOL)enabled
{
    self.saveButton.enabled = enabled;
    self.navigationItem.rightBarButtonItem.enabled = enabled;
}

- (void)_didTapAvatarButton
{
    [self.avatarCreator showOptions];
}

#pragma mark -  AKPickerViewDataSource

- (NSUInteger)numberOfItemsInPickerView:(AKPickerView *)pickerView
{
    return 3;
}

- (NSString *)pickerView:(AKPickerView *)pickerView titleForItem:(NSInteger)item
{
    NSString *str = nil;
    switch (item)
    {
        case 0:
            str = NSLocalizedString(@"Female", nil);
            break;
        case 1:
            str = NSLocalizedString(@"Male", nil);
            break;
        default:
            str = NSLocalizedString(@"Other", nil);
            break;
    }
    return str;
}

#pragma mark - AKPickerViewDelegate

- (void)pickerView:(AKPickerView *)pickerView didSelectItem:(NSInteger)item
{
    self.sex = item;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kProfileCellIdentifier forIndexPath:indexPath];

    if ([cell.contentView subviews])
    {
        for (UIView *subview in [cell.contentView subviews])
        {
            [subview removeFromSuperview];
        }
    }

    cell.backgroundColor = JoyyWhitePure;
    if (indexPath.row == 0)
    {
        [self.avatarContainerView addSubview:self.avatarButton];
        [cell.contentView addSubview:self.avatarContainerView];
        self.avatarContainerView.centerX = cell.centerX;
    }
    else if (indexPath.row == 1)
    {
        [cell.contentView addSubview:self.sexLabel];
        self.sexLabel.x = kMarginLeft;

        [cell.contentView addSubview:self.sexPickerView];
        self.sexPickerView.x = CGRectGetMaxX(self.sexLabel.frame) + 50;
    }
    else
    {
        [cell.contentView addSubview:self.yobTextField];
        self.yobTextField.x = kMarginLeft;
    }

    return cell;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect frame = CGRectMake(0, 0, SCREEN_WIDTH, kHeaderLabelHeight);
    UIView *header = [[UIView alloc] initWithFrame:frame];
    header.backgroundColor = ClearColor;
    [header addSubview:self.headerLabel];

    return header;
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    CGRect frame = CGRectMake(0, 0, SCREEN_WIDTH, kFooterHeight);
    UIView *footer = [[UIView alloc] initWithFrame:frame];
    footer.backgroundColor = ClearColor;

    [footer addSubview:self.saveButton];
    self.saveButton.y = kFooterHeight - self.saveButton.height;

    return footer;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
    {
        return kAvatarButtonHeight + 20;
    }
    return kCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return kHeaderLabelHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return kFooterHeight;
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newStr = [textField.text stringByReplacingCharactersInRange:range withString:string];

    if ([newStr length] == 4)
    {
        uint64_t yob = [newStr uint64Value];
        if (1900 < yob && yob < 2005)
        {
            self.hasYobProvided = YES;
            textField.text = newStr;
            [textField resignFirstResponder];
            [self _enableButtons:(self.avatarImage != nil)];
            return NO;
        }
    }

    self.hasYobProvided = NO;
    [self _enableButtons:NO];

    return [newStr length] < 4;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    self.hasYobProvided = NO;
    [self _enableButtons:NO];

    return YES;
}

#pragma mark - Actions

- (void)_didTapSaveButton
{
    [self _enableButtons:NO];
    [self _updateProfile];
}

- (void)_updateProfile
{
    __weak typeof(self) weakSelf = self;
    [self.avatarCreator uploadAvatarImage:self.avatarImage success:^{

        [weakSelf _updateProfileRecord];
    } failure:^(NSError *error) {
        NSString *errorMessage = nil;
        errorMessage = [error.userInfo valueForKey:NSLocalizedDescriptionKey];

        [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
                       message:errorMessage
               backgroundColor:FlatYellow
                     textColor:FlatBlack
                          time:5];
    }];
}

#pragma mark - JYAvatarCreatorDelegate

- (void)creator:(JYAvatarCreator *)creator didTakePhoto:(UIImage *)image
{
    self.photoButton.imageView.image = image;
    [self.avatarButton removeFromSuperview];
    [self.avatarContainerView addSubview:self.photoButton];

    self.avatarImage = image;
}

#pragma mark - Network

- (void)_updateProfileRecord
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];
    NSString *url = [NSString apiURLWithPath:@"user/profile"];
    NSDictionary *parameters = [self _parametersForUpdatingProfile];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager POST:url
      parameters:parameters
         success:^(NSURLSessionTask *operation, id responseObject) {
             NSLog(@"Success: POST user/profile");
             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

             [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidCreateProfile object:nil];
             [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUserYRSReady object:nil];
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             NSLog(@"Error: POST user/profile error = %@", error);

             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             weakSelf.saveButton.enabled = YES;

             NSString *errorMessage = nil;
             errorMessage = [error.userInfo valueForKey:NSLocalizedDescriptionKey];

             [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
                            message:errorMessage
                    backgroundColor:FlatYellow
                          textColor:FlatBlack
                               time:5];
         }];
}

- (NSDictionary *)_parametersForUpdatingProfile
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    // phone
    NSString *phoneNumber = [JYCredential current].phoneNumber;
    if (!phoneNumber)
    {
        return nil;
    }
    
    [parameters setObject:phoneNumber forKey:@"phone"];

    // YRS
    NSUInteger region = [[JYFilename sharedInstance].region integerValue];
    NSUInteger yob = [self.yobTextField.text integerValue];
    JYYRS *yrs = [JYYRS yrsWithYob:yob region:region sex:self.sex];
    [JYCredential current].yrsValue = yrs.value;
    [parameters setObject:@(yrs.value) forKey:@"yrs"];

    return parameters;
}

@end
