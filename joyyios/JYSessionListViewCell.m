//
//  JYSessionListViewCell.m
//  joyyios
//
//  Created by Ping Yang on 9/3/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYFriendManager.h"
#import "JYMessageDateFormatter.h"
#import "JYSessionListViewCell.h"

static const CGFloat kAvatarImageWidth = 70;
static const CGFloat kTimeLabelWidth = 80;

@interface JYSessionListViewCell ()
@property (nonatomic) JYFriend *friend;
@property (nonatomic) TTTAttributedLabel *nameLabel;
@property (nonatomic) TTTAttributedLabel *messageLabel;
@property (nonatomic) TTTAttributedLabel *timeLabel;
@property (nonatomic) UIImageView *avatarView;
@end

@implementation JYSessionListViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.opaque = YES;
        self.backgroundColor = JoyyWhitePure;
    }
    return self;
}

- (void)setSession:(JYSession *)session
{
    if (!session)
    {
        return;
    }
    _session = session;

    self.messageLabel.text = [_session text];
    self.friend = [[JYFriendManager sharedInstance] friendWithId:session.peerId];

    NSTimeInterval timestamp = [session.timestamp doubleValue];
    NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:timestamp];
    self.timeLabel.text = [[JYMessageDateFormatter sharedInstance] autoStringFromDate:date];
}

- (void)setFriend:(JYFriend *)friend
{
    _friend = friend;

    self.nameLabel.text = friend.username;

    // Fetch avatar image via network
    NSURLRequest *request = [NSURLRequest requestWithURL:friend.avatarThumbnailURL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];

    __weak typeof(self) weakSelf = self;
    [self.avatarView setImageWithURLRequest:request
                           placeholderImage:nil
                                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                        weakSelf.avatarView.image = image;
                                        weakSelf.friend.avatarThumbnailImage = image;

                                   } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                        NSLog(@"setImageWithURLRequest failed with error = %@", error);
                                   }];
}

- (UIImageView *)avatarView
{
    if (!_avatarView)
    {
        CGFloat y = floor((CGRectGetHeight(self.frame) - kAvatarImageWidth) / 2);
        _avatarView = [[UIImageView alloc] initWithFrame:CGRectMake(10, y, kAvatarImageWidth, kAvatarImageWidth)];
        _avatarView.contentMode = UIViewContentModeScaleAspectFit;
        _avatarView.layer.cornerRadius = kAvatarImageWidth / 2;
        _avatarView.layer.masksToBounds = YES;
        [self addSubview:_avatarView];
    }
    return _avatarView;
}

- (TTTAttributedLabel *)timeLabel
{
    if (!_timeLabel)
    {
        CGFloat x = SCREEN_WIDTH - kTimeLabelWidth;
        CGRect frame = CGRectMake(x, 10, kTimeLabelWidth, 30);
        _timeLabel = [[TTTAttributedLabel alloc] initWithFrame:frame];
        _timeLabel.textInsets = UIEdgeInsetsMake(0, 0, 0, 8);
        _timeLabel.backgroundColor = JoyyWhitePure;
        _timeLabel.font = [UIFont systemFontOfSize:15];
        _timeLabel.textColor = JoyyGray;
        _timeLabel.textAlignment = NSTextAlignmentRight;
        [self addSubview:_timeLabel];
    }
    return _timeLabel;
}

- (TTTAttributedLabel *)nameLabel
{
    if (!_nameLabel)
    {
        CGFloat x = CGRectGetMaxX(self.avatarView.frame);
        CGFloat width = SCREEN_WIDTH - kTimeLabelWidth - x;
        CGRect frame = CGRectMake(x, 10, width, 30);
        _nameLabel = [[TTTAttributedLabel alloc] initWithFrame:frame];
        _nameLabel.textInsets = UIEdgeInsetsMake(0, 10, 0, 0);
        _nameLabel.backgroundColor = JoyyWhitePure;
        _nameLabel.font = [UIFont systemFontOfSize:19];
        _nameLabel.textColor = JoyyBlack;
        _nameLabel.textAlignment = NSTextAlignmentLeft;
        [self addSubview:_nameLabel];
    }
    return _nameLabel;
}

- (TTTAttributedLabel *)messageLabel
{
    if (!_messageLabel)
    {
        CGFloat x = CGRectGetMaxX(self.avatarView.frame);
        CGFloat y = CGRectGetMaxY(self.nameLabel.frame);
        CGFloat width = SCREEN_WIDTH - x;
        CGRect frame = CGRectMake(x, y, width, 20);
        _messageLabel = [[TTTAttributedLabel alloc] initWithFrame:frame];
        _messageLabel.textInsets = UIEdgeInsetsMake(0, 10, 0, kMarginRight);
        _messageLabel.backgroundColor = JoyyWhitePure;
        _messageLabel.font = [UIFont systemFontOfSize:15];
        _messageLabel.textColor = JoyyGray;
        _messageLabel.textAlignment = NSTextAlignmentLeft;
        [self addSubview:_messageLabel];
    }
    return _messageLabel;
}

@end
