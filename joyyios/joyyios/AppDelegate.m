//
//  AppDelegate.m
//  joyyios
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <AWSCore/AWSCore.h>
#import <AWSS3/AWSS3.h>
#import <Crashlytics/Crashlytics.h>
#import <Fabric/Fabric.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "AppDelegate.h"
#import "Flurry.h"
#import "JYAmazonClientManager.h"
#import "JYButton.h"
#import "JYContactManager.h"
#import "JYCredentialManager.h"
#import "JYDeviceManager.h"
#import "JYFilename.h"
#import "JYFriendManager.h"
#import "JYLocalDataManager.h"
#import "JYManagementDataStore.h"
#import "JYPeopleViewController.h"
#import "JYPhoneNumberViewController.h"
#import "JYProfileCreationViewController.h"
#import "JYProfileViewController.h"
#import "JYSessionListViewController.h"
#import "JYSoundPlayer.h"
#import "JYTimelineViewController.h"
#import "JYXmppManager.h"
#import "OnboardingViewController.h"
#import "OnboardingContentViewController.h"
#import "UITabBarItem+Joyy.h"

@interface AppDelegate ()
@property (nonatomic) OnboardingContentViewController *page1;
@property (nonatomic) OnboardingContentViewController *page2;
@property (nonatomic) OnboardingContentViewController *page3;
@property (nonatomic) OnboardingViewController *onboardingViewController;
@property (nonatomic) UITabBarController *tabBarController;

@property (nonatomic) JYAmazonClientManager *amazonClientManager;
@property (nonatomic) JYCredentialManager *credentialManager;
@property (nonatomic) JYDeviceManager *deviceManager;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"didFinishLaunchingWithOptions");

    // test only
//    [[JYCredential current] clear];

    // Fabric crashlytics
//    [Fabric with:@[[Crashlytics class]]];
    [Flurry startSession:kFlurryKey];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didManuallySignIn) name:kNotificationDidSignIn object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didManuallySignUp) name:kNotificationDidSignUp object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didCreateProfile) name:kNotificationDidCreateProfile object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didChangeRedDot:) name:kNotificationDidChangeRedDot object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_updateBadgeCount:) name:kNotificationUpdateBadgeCount object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_willChatWithFriend:) name:kNotificationWillChat object:nil];

    [self _setupGlobalAppearance];
    [self _launchViewController];
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"applicationWillResignActive");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"applicationDidEnterBackground");
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationAppDidStop object:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"applicationWillEnterForeground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"applicationDidBecomeActive");
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationAppDidStart object:nil];

    [[JYLocalDataManager sharedInstance] start];
    [[JYFriendManager sharedInstance] start];
    [[JYXmppManager sharedInstance] start];

    [self.deviceManager start];
    [self.locationManager start];
    [self.amazonClientManager start];
    [self.credentialManager start];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"applicationWillTerminate");
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationAppDidStop object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (JYAmazonClientManager *)amazonClientManager
{
    if (!_amazonClientManager)
    {
        _amazonClientManager = [JYAmazonClientManager new];
    }
    return _amazonClientManager;
}

- (JYCredentialManager *)credentialManager
{
    if (!_credentialManager)
    {
        _credentialManager = [JYCredentialManager new];
    }
    return _credentialManager;
}

- (JYDeviceManager *)deviceManager
{
    if (!_deviceManager)
    {
        _deviceManager = [JYDeviceManager new];
    }
    return _deviceManager;
}

#pragma mark - Notifications

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];

    self.deviceManager.deviceToken = token;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)notification
{
    NSLog(@"Notification = %@", notification);
    self.tabBarController.selectedIndex = 2;
}

#pragma mark - Private methods

- (void)_setupGlobalAppearance
{
    self.window.backgroundColor = JoyyWhitePure;

    [[UINavigationBar appearance] setTintColor:JoyyBlue];
    [[UITabBar appearance] setTintColor:JoyyBlue];
}

- (void)_launchViewController
{
    if (![JYManagementDataStore sharedInstance].didShowIntroduction)
    {
        [self _launchIntroductionViewController];
        return;
    }

    if ([[JYCredential current] isInvalid])
    {
        [self _launchSignViewController];
        return;
    }

    if ([JYCredential current].yrsValue == 0)
    {
        [self _launchProfileViewController];
        return;
    }

    [self _launchMainViewController];
}

- (void)_introductionDidFinish
{
    // Update introduction history to avoid duplicated presenting
    [JYManagementDataStore sharedInstance].didShowIntroduction = YES;
    [self _launchViewController];
}

- (void)_launchSignViewController
{
    UIViewController *viewController = [JYPhoneNumberViewController new];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    self.window.rootViewController = navigationController;
}

- (void)_launchProfileViewController
{
    UIViewController *viewController = [JYProfileCreationViewController new];
    self.window.rootViewController = viewController;
}

- (void)_launchIntroductionViewController
{
    self.window.rootViewController = self.onboardingViewController;
}

- (void)_launchMainViewController
{
    [[JYContactManager sharedInstance] start];
    self.window.rootViewController = self.tabBarController;
    self.onboardingViewController = nil;
}

- (UITabBarController *)tabBarController
{
    if (_tabBarController)
    {
        return _tabBarController;
    }

    _tabBarController = [UITabBarController new];

    UIViewController *vc1 = [JYPeopleViewController new];
    UINavigationController *nc1 = [[UINavigationController alloc] initWithRootViewController:vc1];

    UIViewController *vc2 = [JYTimelineViewController new];
    UINavigationController *nc2 = [[UINavigationController alloc] initWithRootViewController:vc2];

    UIViewController *vc3 = [JYSessionListViewController new];
    UINavigationController *nc3 = [[UINavigationController alloc] initWithRootViewController:vc3];

    UIViewController *vc4 = [JYProfileViewController new];
    UINavigationController *nc4 = [[UINavigationController alloc] initWithRootViewController:vc4];

    _tabBarController.viewControllers = @[ nc1, nc2, nc3, nc4 ];

    UITabBar *tabBar = _tabBarController.tabBar;
    UITabBarItem *tabBarItem1 = [tabBar.items objectAtIndex:0];
    UITabBarItem *tabBarItem2 = [tabBar.items objectAtIndex:1];
    UITabBarItem *tabBarItem3 = [tabBar.items objectAtIndex:2];
    UITabBarItem *tabBarItem4 = [tabBar.items objectAtIndex:3];

    tabBarItem1.selectedImage = [[UIImage imageNamed:@"people_selected"]imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem1.image = [[UIImage imageNamed:@"people"]imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem1.title = NSLocalizedString(@"People", nil);

    tabBarItem2.selectedImage = [[UIImage imageNamed:@"feeds_selected"] imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem2.image = [[UIImage imageNamed:@"feeds"] imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem2.title = NSLocalizedString(@"Feeds", nil);

    tabBarItem3.selectedImage = [[UIImage imageNamed:@"chat_selected"]imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem3.image = [[UIImage imageNamed:@"chat"]imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem3.title = NSLocalizedString(@"Chat", nil);

    tabBarItem4.selectedImage = [[UIImage imageNamed:@"me_selected"]imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem4.image = [[UIImage imageNamed:@"me"]imageWithRenderingMode:UIImageRenderingModeAutomatic];
    tabBarItem4.title = NSLocalizedString(@"Me", nil);

    return _tabBarController;
}

- (void)_didChangeRedDot:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    if (!info)
    {
        return;
    }

    id index = [info objectForKey:@"index"];
    id show = [info objectForKey:@"show"];

    if (index == [NSNull null] && show == [NSNull null])
    {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        NSUInteger itemIndex = [index unsignedIntegerValue];
        BOOL shouldShow = [show boolValue];
        [self.tabBarController.tabBar.items[itemIndex] showRedDot:shouldShow];
    });
}

- (void)_didManuallySignIn
{
    [self.credentialManager start];
    [self _launchMainViewController];
}

- (void)_didManuallySignUp
{
    [self.credentialManager start];
    [self _launchProfileViewController];
}

- (void)_didCreateProfile
{
    [self _launchMainViewController];
}

- (void)_updateBadgeCount:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    if (!info)
    {
        return;
    }

    id obj = [info objectForKey:@"delta"];
    if (obj == [NSNull null])
    {
        return;
    }

    NSNumber *delta = (NSNumber *)obj;
    UIApplication *application = [UIApplication sharedApplication];
    NSInteger newValue =  application.applicationIconBadgeNumber + [delta integerValue];
    application.applicationIconBadgeNumber = (newValue >= 0)? newValue: 0;

    [self.deviceManager updateDeviceBadgeCount:application.applicationIconBadgeNumber];
}

- (void)_willChatWithFriend:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    if (!info)
    {
        return;
    }

    id obj = [info objectForKey:@"friend"];
    if (obj == [NSNull null])
    {
        return;
    }

    self.tabBarController.selectedIndex = 2;

    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationChatting object:nil userInfo:info];
}

#pragma mark - Introduction Pages

- (OnboardingViewController *)onboardingViewController
{
    if (_onboardingViewController)
    {
        return _onboardingViewController;
    }

    NSArray *pages = @[ self.page1, self.page2, self.page3 ];
    _onboardingViewController = [OnboardingViewController onboardWithBackgroundImage:[UIImage imageNamed:@"street"] contents:pages];
    _onboardingViewController.shouldFadeTransitions = YES;
    _onboardingViewController.fadePageControlOnLastPage = YES;

    // Allow skipping the onboarding process
    _onboardingViewController.allowSkipping = YES;
    __weak typeof(self) weakSelf = self;
    _onboardingViewController.skipHandler = ^{
        [weakSelf _introductionDidFinish];
    };

    return _onboardingViewController;
}

- (OnboardingContentViewController *)page1
{
    if (_page1)
    {
        return _page1;
    }

    __weak typeof(self) weakSelf = self;
    _page1 = [OnboardingContentViewController contentWithTitle:@"Get Service Anytime Anywhere"
                                                          body:@"People arround you are glad to serve you..."
                                                         image:[UIImage imageNamed:@"blue"]
                                                    buttonText:@"Get Started"
                                                        action:^{
                                                            [weakSelf _introductionDidFinish];
                                                        }];
    return _page1;
}

- (OnboardingContentViewController *)page2
{
    if (_page2)
    {
        return _page2;
    }

    __weak typeof(self) weakSelf = self;
    _page2 = [OnboardingContentViewController contentWithTitle:@"Get Service Anytime Anywhere"
                                                          body:@"People arround you are glad to serve you..."
                                                         image:[UIImage imageNamed:@"blue"]
                                                    buttonText:@"Get Started"
                                                        action:^{
                                                            [weakSelf _introductionDidFinish];
                                                        }];
    _page2.movesToNextViewController = YES;
    return _page2;
}

- (OnboardingContentViewController *)page3
{
    if (_page3)
    {
        return _page3;
    }

    __weak typeof(self) weakSelf = self;
    _page3 = [OnboardingContentViewController contentWithTitle:@"Welcome To Joyy"
                                                          body:@"All men are created equal, that they are endowed by their Creator with certain unalienable Rights, that among these are Life, Liberty, iPhone and \n Joyy."
                                                         image:[UIImage imageNamed:@"yellow"]
                                                    buttonText:@"Get Started"
                                                        action:^{
                                                            [weakSelf _introductionDidFinish];
                                                        }];
    return _page3;
}

@end
