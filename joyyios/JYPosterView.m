//
//  JYPosterView.m
//  joyyios
//
//  Created by Ping Yang on 11/26/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYButton.h"
#import "JYFriendManager.h"
#import "JYPost.h"
#import "JYPosterView.h"
#import "NSDate+Joyy.h"

@interface JYPosterView ()
@property (nonatomic) BOOL didSetupConstraints;
@property (nonatomic) UIButton *avatarButton;
@property (nonatomic) TTTAttributedLabel *posterNameLabel;
@property (nonatomic) TTTAttributedLabel *postTimeLabel;
@end


@implementation JYPosterView

- (instancetype)init
{
    if (self = [super init])
    {
        self.translatesAutoresizingMaskIntoConstraints = NO;

        [self addSubview:self.avatarButton];
        [self addSubview:self.posterNameLabel];
        [self addSubview:self.postTimeLabel];

        NSDictionary *views = @{
                                @"avatarButton": self.avatarButton,
                                @"posterNameLabel": self.posterNameLabel,
                                @"postTimeLabel": self.postTimeLabel
                              };

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[avatarButton(40)][posterNameLabel][postTimeLabel(50)]-8-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[avatarButton]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[posterNameLabel]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[postTimeLabel]|" options:0 metrics:nil views:views]];
    }
    return self;
}

- (void)setPost:(JYPost *)post
{
    if (!post)
    {
        NSAssert(NO, @"post should not be nil");
        return;
    }

    _post = post;

    [self _updateAvatarButtonImage];

    JYFriend *poster = [[JYFriendManager sharedInstance] friendOfId:self.post.ownerId];
    if (poster)
    {
        self.posterNameLabel.text = poster.username;
    }

    NSDate *date = [NSDate dateOfId:self.post.postId];
    self.postTimeLabel.text = [date ageString];
}

- (void)_updateAvatarButtonImage
{
    JYFriend *friend = [[JYFriendManager sharedInstance] friendOfId:self.post.ownerId];
    NSURL *url = [NSURL URLWithString:friend.avatarURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];

    __weak typeof(self) weakSelf = self;
    [self.avatarButton.imageView setImageWithURLRequest:request
                                       placeholderImage:nil
                                                success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                    weakSelf.avatarButton.imageView.image = image;

                                                } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                    NSLog(@"setImageWithURLRequest failed with error = %@", error);
                                                }];
}

- (UIButton *)avatarButton
{
    if (!_avatarButton)
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [button addTarget:self action:@selector(_showProfile) forControlEvents:UIControlEventTouchUpInside];
        [button setImage:[UIImage imageNamed:@"wink"] forState:UIControlStateNormal];
        button.clipsToBounds = YES;
        button.layer.cornerRadius = 20;
        button.contentEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4);

        _avatarButton = button;
    }
    return _avatarButton;
}

- (TTTAttributedLabel *)posterNameLabel
{
    if (!_posterNameLabel)
    {
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [UIFont systemFontOfSize:kFontSizeCaption];
        label.textColor = JoyyBlue;
        label.backgroundColor = JoyyWhitePure;
        label.textAlignment = NSTextAlignmentLeft;
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;

        _posterNameLabel = label;
    }
    return _posterNameLabel;
}

- (TTTAttributedLabel *)postTimeLabel
{
    if (!_postTimeLabel)
    {
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [UIFont systemFontOfSize:kFontSizeDetail];
        label.textColor = JoyyGray;
        label.backgroundColor = JoyyWhitePure;
        label.textAlignment = NSTextAlignmentRight;
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;

        _postTimeLabel = label;
    }
    return _postTimeLabel;
}

- (void)_showProfile
{

}

@end
