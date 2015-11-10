//
//  JYAmazonClientManager.m
//  joyyios
//
//  Created by Ping Yang on 9/1/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYAmazonClientManager.h"
#import "JYAuthenticatedIdentityProvider.h"
#import "JYAuthenticationClient.h"


@interface JYAmazonClientManager()
@property (nonatomic) AWSCognitoCredentialsProvider *credentialsProvider;
@property (nonatomic) JYAuthenticationClient *authClient;
@end

@implementation JYAmazonClientManager

+ (JYAmazonClientManager *)sharedInstance
{
    static JYAmazonClientManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [JYAmazonClientManager new];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
         self.authClient = [JYAuthenticationClient new];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_apiTokenReady) name:kNotificationAPITokenReady object:nil];
    }
    return self;
}

- (void)start
{
    NSLog(@"AmazonClientManager started");
}

- (void)_apiTokenReady
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self _getCognitoToken:@{ kAuthProviderName: [JYCredential current].idString }];
    });
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_getCognitoToken:(NSDictionary *)logins
{
    if (self.credentialsProvider == nil)
    {
        [self _initializeProviders:logins];
    }
    else
    {
        [self.credentialsProvider refresh];
    }
}

- (AWSTask *)_initializeProviders:(NSDictionary *)logins
{
    NSLog(@"initializing providers...");
    [AWSLogger defaultLogger].logLevel = AWSLogLevelDebug;

    id<AWSCognitoIdentityProvider> identityProvider = [[JYAuthenticatedIdentityProvider alloc] initWithRegionType:kCognitoRegionType identityId:nil identityPoolId:kCognitoIdentityPoolId logins:logins providerName:kAuthProviderName authClient:self.authClient];

    self.credentialsProvider = [[AWSCognitoCredentialsProvider alloc] initWithRegionType:kCognitoRegionType identityProvider:identityProvider unauthRoleArn:nil authRoleArn:nil];

    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:kCognitoRegionType credentialsProvider:self.credentialsProvider];
    configuration.maxRetryCount = 5;

    AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = configuration;

//    AWSTask *task = [self.credentialsProvider refresh];
//    return [task continueWithBlock:nil];
    return [self.credentialsProvider refresh];
}

@end
