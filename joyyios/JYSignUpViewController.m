//
//  JYSignUpViewController.m
//  joyyios
//
//  Created by Ping Yang on 3/28/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "JYButton.h"
#import "JYFloatLabeledTextField.h"
#import "JYSignUpViewController.h"

@interface JYSignUpViewController ()

@end

@implementation JYSignUpViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Create Account", nil);

    self.signButton.textLabel.text = NSLocalizedString(@"Sign Up", nil);
    self.signButton.foregroundColor = FlatSkyBlue;

    [self.signButton addTarget:self action:@selector(_signUp) forControlEvents:UIControlEventTouchUpInside];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)signButtonPressed
{
    [self _signUp];
}

- (void)_signUp
{
    if (![self inputCheckPassed])
    {
        return;
    }

    NSString *email = [self.emailField.text lowercaseString];
    NSString *password = self.passwordField.text;
    [JYCredential mine].password = password;
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    NSString *url = [NSString apiURLWithPath:@"signup"];
    NSDictionary *parameters = @{@"email": email, @"password": password};

    [KVNProgress show];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    [manager POST:url
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"SignUp Success responseObject: %@", responseObject);

             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             [KVNProgress dismiss];
             [[JYCredential mine] save:responseObject];
             [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidSignUp object:nil];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"SignUp Error: %@", error);

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

             [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
                            message:errorMessage
                    backgroundColor:FlatYellow
                          textColor:FlatBlack
                               time:5];
         }];
}

@end
