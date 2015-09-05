//
//  JYSignInViewController.m
//  joyy
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "JYButton.h"
#import "JYFloatLabeledTextField.h"
#import "JYSignInViewController.h"

@interface JYSignInViewController ()

@end

@implementation JYSignInViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Welcome Back!", nil);

    self.signButton.textLabel.text = NSLocalizedString(@"Sign In", nil);

    [self.signButton addTarget:self action:@selector(_signIn) forControlEvents:UIControlEventTouchUpInside];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)signButtonPressed
{
    [self _signIn];
}

- (void)_signIn
{
    if (![self inputCheckPassed])
    {
        return;
    }

    NSString *email = [self.emailField.text lowercaseString];
    NSString *password = self.passwordField.text;

    NSLog(@"password = %@", password);

    [JYCredential mine].email = email;
    [JYCredential mine].password = password;

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager managerWithPassword];
    NSString *url = [NSString apiURLWithPath:@"signin"];

    [KVNProgress show];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    [manager GET:url
        parameters:nil
        success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"SignIn Success responseObject: %@", responseObject);

            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            [KVNProgress dismiss];
            [[JYCredential mine] save:responseObject];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidSignIn object:nil];
        }
        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"SignIn Error: %@", error);

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
