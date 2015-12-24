//
//  JYProfileViewController.m
//  joyyios
//
//  Created by Ping Yang on 12/23/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <AWSS3/AWSS3.h>
#import <MJRefresh/MJRefresh.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "JYMonth.h"
#import "JYButton.h"
#import "JYComment.h"
#import "JYCommentViewController.h"
#import "JYFilename.h"
#import "JYFriendManager.h"
#import "JYFriendViewController.h"
#import "JYLocalDataManager.h"
#import "JYPhotoCaptionViewController.h"
#import "JYProfileCardView.h"
#import "JYProfileViewController.h"
#import "JYPost.h"
#import "JYUserlineCell.h"
#import "JYWinkViewController.h"
#import "TGCameraColor.h"
#import "TGCameraViewController.h"
#import "UIImage+Joyy.h"

@interface JYProfileViewController () <TGCameraDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) JYMonth *month;
@property (nonatomic) JYUser *user;
@property (nonatomic) JYProfileCardView *cardView;
@property (nonatomic) NSInteger networkThreadCount;
@property (nonatomic) NSMutableArray *friendList;
@property (nonatomic) NSMutableArray *postList;
@property (nonatomic) NSMutableArray *winkList;
@property (nonatomic) UITableView *tableView;
@end

static NSString *const kCellIdentifier = @"profileUserlineCell";

@implementation JYProfileViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Me", nil);
    self.navigationController.navigationBar.translucent = YES;

    self.networkThreadCount = 0;
    self.postList = [NSMutableArray new];
    self.month = [[JYMonth alloc] initWithDate:[NSDate date]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_apiTokenReady) name:kNotificationAPITokenReady object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_tapOnFriendCount) name:kNotificationDidTapOnFriendCount object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_tapOnInviteCount) name:kNotificationDidTapOnInviteCount object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_tapOnWinkCount) name:kNotificationDidTapOnWinkCount object:nil];

    self.user = [JYFriend myself];

    if (self.user)
    {
        [self _initSubViews];
    }
}

- (void)_initSubViews
{
    [self.view addSubview:self.tableView];

    [self _fetchFriends];
//    [self _fetchWinks];
    [self _fetchUserline];
}

- (UITableView *)tableView
{
    if (!_tableView)
    {
        _tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsVerticalScrollIndicator = YES;
        _tableView.tableHeaderView = self.cardView;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.estimatedRowHeight = 415;
        [_tableView registerClass:[JYUserlineCell class] forCellReuseIdentifier:kCellIdentifier];

        // Setup the pull-up-to-refresh footer
        MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(_fetchUserline)];
        footer.refreshingTitleHidden = YES;
        footer.stateLabel.hidden = YES;
        _tableView.mj_footer = footer;
    }
    return _tableView;
}

- (JYProfileCardView *)cardView
{
    if (!_cardView)
    {
        _cardView = [JYProfileCardView new];
        _cardView.user = self.user;
    }
    return _cardView;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_apiTokenReady
{
    if (!self.user)
    {
        self.user = [JYFriend myself];
        [self _initSubViews];
    }
}

// TODO
- (void)_tapOnFriendCount
{
    if ([self.friendList count] > 0)
    {
        JYFriendViewController *viewController = [[JYFriendViewController alloc] initWithFriendList:self.friendList];
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

- (void)_tapOnInviteCount
{
    
}

- (void)_tapOnWinkCount
{
// test only
//    JYUser *user = [JYFriend myself];
//    self.winkList = [NSMutableArray new];
//    for (int i = 0; i < 10; ++i)
//    {
//        [self.winkList addObject:user];
//    }
//

    if ([self.winkList count] > 0)
    {
        JYWinkViewController *viewController = [[JYWinkViewController alloc] initWithWinkList:self.winkList];
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

- (void)_networkThreadBegin
{
    if (self.networkThreadCount == 0)
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
    self.networkThreadCount++;
}

- (void)_networkThreadEnd
{
    self.networkThreadCount--;
    if (self.networkThreadCount <= 0)
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [self.tableView.mj_footer endRefreshing];
    }
}

- (void)_showCamera
{
    JYPhotoCaptionViewController *captionVC = [[JYPhotoCaptionViewController alloc] initWithDelegate:self];

    [TGCameraColor setTintColor:JoyyBlue];
    TGCameraNavigationController *camera = [TGCameraNavigationController cameraWithDelegate:self captionViewController:captionVC];
    camera.title = self.title;

    [self presentViewController:camera animated:NO completion:nil];
}

#pragma mark - TGCameraDelegate Methods

- (void)cameraDidCancel
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)cameraDidTakePhoto:(UIImage *)photo fromAlbum:(BOOL)fromAlbum withCaption:(NSString *)caption
{
    // Handling and upload the photo
    //    UIImage *image = [UIImage imageWithImage:photo scaledToSize:CGSizeMake(kPhotoWidth, kPhotoWidth)];
    //
    ////    [self _createPostWithImage:image contentType:kContentTypeJPG caption:caption];
    ////    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.postList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYUserlineCell *cell =
    (JYUserlineCell *)[tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];

    JYPost *post = self.postList[indexPath.row];
    cell.post = post;

    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];

    return cell;
}

#pragma mark - UITableView Delegate

#pragma mark - Maintain table

//- (void)_createdNewPost:(JYPost *)post
//{
//    if (!post)
//    {
//        return;
//    }
//
//    [[JYLocalDataManager sharedInstance] insertObjects:@[post] ofClass:JYPost.class];
//
//    self.oldestPostId = post.postId;
//
//    [self.postList insertObject:post atIndex:0];
//    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
//    [self.tableView beginUpdates];
//    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
//    [self.tableView endUpdates];
//}

- (void)_receivedOldPosts:(NSMutableArray *)postList
{
    if ([postList count] == 0) // no more old post, do nothing
    {
        return;
    }

    [self.postList addObjectsFromArray:postList];
    [self.tableView reloadData];
    [self.tableView.mj_footer endRefreshing];
}

#pragma mark - AWS S3

- (void)_createPostWithImage:(UIImage *)image contentType:(NSString *)contentType caption:(NSString *)caption
{
    //    NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"timeline"]];
    //
    //    NSData *imageData = UIImageJPEGRepresentation(image, kPhotoQuality);
    //    [imageData writeToURL:fileURL atomically:YES];
    //
    //    NSString *s3filename = [[JYFilename sharedInstance] randomFilenameWithHttpContentType:contentType];
    //    NSString *s3region = [JYFilename sharedInstance].region;
    //    NSString *s3url = [NSString stringWithFormat:@"%@:%@", s3region, s3filename];
    //
    //    AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
    //    if (!transferManager)
    //    {
    //        NSLog(@"Error: no S3 transferManager");
    //        return;
    //    }
    //
    //    AWSS3TransferManagerUploadRequest *request = [AWSS3TransferManagerUploadRequest new];
    //    request.bucket = [JYFilename sharedInstance].postBucketName;
    //    request.key = s3filename;
    //    request.body = fileURL;
    //    request.contentType = contentType;
    //
    //    __weak typeof(self) weakSelf = self;
    //    [[transferManager upload:request] continueWithBlock:^id(AWSTask *task) {
    //        if (task.error)
    //        {
    //            if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain])
    //            {
    //                switch (task.error.code)
    //                {
    //                    case AWSS3TransferManagerErrorCancelled:
    //                    case AWSS3TransferManagerErrorPaused:
    //                        break;
    //                    default:
    //                        NSLog(@"Error: AWSS3TransferManager upload error = %@", task.error);
    //                        break;
    //                }
    //            }
    //            else
    //            {
    //                // Unknown error.
    //                NSLog(@"Error: AWSS3TransferManager upload error = %@", task.error);
    //            }
    //        }
    //        if (task.result)
    //        {
    //            AWSS3TransferManagerUploadOutput *uploadOutput = task.result;
    //            NSLog(@"Success: AWSS3TransferManager upload task.result = %@", uploadOutput);
    //            [weakSelf _createPostRecordWithS3URL:s3url caption:caption localImage:image];
    //        }
    //        return nil;
    //    }];
}

#pragma mark - Network

- (void)_fetchUserline
{
    if (self.networkThreadCount > 0)
    {
        return;
    }

    uint64_t monthValue = self.month.value;
    self.month = [self.month prev];
    [self _fetchUserlineOfMonth:monthValue];
}

- (void)_fetchUserlineOfMonth:(uint64_t)month
{
    [self _networkThreadBegin];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];

    NSString *url = [NSString apiURLWithPath:@"post/userline"];
    NSDictionary *parameters = @{@"userid": @([self.user.userId unsignedLongLongValue]), @"month": @(month)};

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(NSURLSessionTask *operation, id responseObject) {
             NSLog(@"post/userline fetch success responseObject: %@", responseObject);

             // the post json is in ASC order, so iterate reversely
             NSMutableArray *postList = [NSMutableArray new];
             for (NSDictionary *dict in [responseObject reverseObjectEnumerator])
             {
                 NSError *error = nil;
                 JYPost *post = (JYPost *)[MTLJSONAdapter modelOfClass:JYPost.class fromJSONDictionary:dict error:&error];
                 if (post)
                 {
                     [postList addObject:post];
                 }
             }

             [weakSelf _receivedOldPosts:postList];
             [weakSelf _networkThreadEnd];
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             NSLog(@"Error: post/userline fetch failed with error: %@", error);
             [weakSelf _networkThreadEnd];
         }
     ];
}

- (void)_fetchFriends
{
    NSString *url = [NSString apiURLWithPath:@"friends"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:nil
         success:^(NSURLSessionTask *operation, id responseObject) {
             NSLog(@"GET friends Success");

             NSMutableArray *friendList = [NSMutableArray new];
             for (NSDictionary *dict in responseObject)
             {
                 NSError *error = nil;
                 JYFriend *friend = (JYFriend *)[MTLJSONAdapter modelOfClass:JYFriend.class fromJSONDictionary:dict error:&error];
                 if (friend)
                 {
                     [friendList addObject:friend];
                 }
             }

//              test only
//                 JYUser *user = [JYFriend myself];
//                 for (int i = 0; i < 10; ++i)
//                 {
//                     [friendList addObject:user];
//                 }
//

             weakSelf.friendList = friendList;
             weakSelf.cardView.friendCount = [friendList count];
             [[JYFriendManager sharedInstance] receivedFriendList:friendList];
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             NSLog(@"GET friends error: %@", error);
         }];
}

- (void)_fetchWinks
{
    NSString *url = [NSString apiURLWithPath:@"winks"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:nil
         success:^(NSURLSessionTask *operation, id responseObject) {
             NSLog(@"GET winks Success");

             NSMutableArray *winkList = [NSMutableArray new];
             for (NSDictionary *dict in responseObject)
             {
                 NSError *error = nil;
                 JYUser *user = (JYUser *)[MTLJSONAdapter modelOfClass:JYUser.class fromJSONDictionary:dict error:&error];
                 if (user)
                 {
                     [winkList addObject:user];
                 }
             }
             weakSelf.winkList = winkList;
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             NSLog(@"GET winks error: %@", error);
         }];
}

@end
