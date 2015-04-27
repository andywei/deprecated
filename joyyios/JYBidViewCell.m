//
//  JYBidViewCell.m
//  joyyios
//
//  Created by Ping Yang on 4/25/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AXRatingView/AXRatingView.h>

#import "JYBidViewCell.h"

static const CGFloat kBidderNameLabelHeight = 35;
static const CGFloat kBidderNameLabelWidth = 150;
static const CGFloat kLabelHeight = 60.0f;
static const CGFloat kLeftMargin = 8.0f;
static const CGFloat kRatingViewHeight = 20;
static const CGFloat kRatingViewWidth = 70;
static const CGFloat kRightMargin = 8.0f;
static const CGFloat kTopMargin = 8.0f;
static const CGFloat kTinyFontSize = 13.0f;

@interface JYBidViewCell ()

@property(nonatomic) AXRatingView *ratingView;
@property(nonatomic) UILabel *expireTimeLabel;
@property(nonatomic) UILabel *ratingCountLabel;

@end


@implementation JYBidViewCell


+ (CGFloat)cellHeight
{
    return kTopMargin + kLabelHeight;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.opaque = YES;
        self.backgroundColor = [UIColor whiteColor];

        [self _createBidderNameLabel];
        [self _createRatingView];
        [self _createRatingCountLabel];
        [self _createExpireTimeLabel];
        [self _createPriceLabel];
    }
    return self;
}

- (void)setExpireTime:(NSTimeInterval)expireAt
{
    NSDate *expireTime = [NSDate dateWithTimeIntervalSinceReferenceDate:expireAt];
    NSTimeInterval secondsBetween = [expireTime timeIntervalSinceNow];

    if (secondsBetween < 0)
    {
        self.expireTimeLabel.text = NSLocalizedString(@"expired", nil);
        return;
    }

    NSString *expireString = NSLocalizedString(@"expire in", nil);
    int numberOfDays = secondsBetween / 86400;
    if (numberOfDays > 0)
    {
        NSString *days = (numberOfDays == 1) ? NSLocalizedString(@"day", nil) : NSLocalizedString(@"days", nil);

        self.expireTimeLabel.text = [NSString stringWithFormat:@"%@ %d %@", expireString, numberOfDays, days];
        return;
    }

    int numberOfHours = secondsBetween / 3600;
    if (numberOfHours > 0)
    {
        NSString *hours = (numberOfHours == 1) ? NSLocalizedString(@"hour", nil) : NSLocalizedString(@"hours", nil);

        self.expireTimeLabel.text = [NSString stringWithFormat:@"%@ %d %@", expireString, numberOfHours, hours];
        return;
    }

    int numberOfMinutes = secondsBetween / 60;
    if (numberOfMinutes > 0)
    {
        NSString *minutes = (numberOfMinutes == 1) ? NSLocalizedString(@"min", nil) : NSLocalizedString(@"mins", nil);

        self.expireTimeLabel.text = [NSString stringWithFormat:@"%@ %d %@", expireString, numberOfMinutes, minutes];
        return;
    }

    int numberOfSeconds = (int)secondsBetween;
    NSString *seconds = (numberOfSeconds == 1) ? NSLocalizedString(@"sec", nil) : NSLocalizedString(@"secs", nil);
    self.expireTimeLabel.text = [NSString stringWithFormat:@"%@ %d %@", expireString, numberOfSeconds, seconds];
}

- (void)setRatingTotalScore:(CGFloat)score count:(NSUInteger)count
{
    self.ratingView.value = (count == 0) ? 0 : score/count;
    self.ratingCountLabel.text = [NSString stringWithFormat:@"(%tu)", count];
}

- (void)_createBidderNameLabel
{
    self.bidderNameLabel = [self _createLabel];
    self.bidderNameLabel.frame = CGRectMake(kLeftMargin + 5, kTopMargin, kBidderNameLabelWidth, kBidderNameLabelHeight);
    self.bidderNameLabel.adjustsFontSizeToFitWidth = YES;
    [self addSubview:self.bidderNameLabel];
}

- (void)_createRatingView
{
    CGFloat y = CGRectGetMaxY(self.bidderNameLabel.frame);
    CGRect frame = CGRectMake(kLeftMargin, y, kRatingViewWidth, kRatingViewHeight);
    self.ratingView = [[AXRatingView alloc] initWithFrame:frame];
    self.ratingView.markFont = [UIFont systemFontOfSize:kTinyFontSize];
    [self.ratingView setStepInterval:0.5];
    [self addSubview:self.ratingView];
}

- (void)_createRatingCountLabel
{
    CGFloat x = CGRectGetMaxX(self.ratingView.frame);
    CGFloat y = CGRectGetMaxY(self.bidderNameLabel.frame);
    self.ratingCountLabel = [self _createLabel];
    self.ratingCountLabel.frame = CGRectMake(x, y, kBidderNameLabelWidth - kRatingViewWidth, kRatingViewHeight);
    self.ratingCountLabel.font = [UIFont systemFontOfSize:kTinyFontSize];
}


- (void)_createExpireTimeLabel
{
    self.expireTimeLabel = [self _createLabel];
    CGFloat x = kLeftMargin + CGRectGetMaxX(self.bidderNameLabel.frame);
    self.expireTimeLabel.frame = CGRectMake(x, CGRectGetMaxY(self.bidderNameLabel.frame), 120, kRatingViewHeight);
    self.expireTimeLabel.font = [UIFont systemFontOfSize:kTinyFontSize];
}

- (void)_createPriceLabel
{
    self.priceLabel = [self _createLabel];
    self.priceLabel.textAlignment = NSTextAlignmentRight;

    CGFloat x = CGRectGetMaxX(self.expireTimeLabel.frame);
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]) - x - kRightMargin;
    self.priceLabel.frame = CGRectMake(x, kTopMargin, width, kLabelHeight);
}

- (UILabel *)_createLabel
{
    UILabel *label = [UILabel new];
    label.backgroundColor = [UIColor whiteColor];
    label.opaque = YES;
    label.font = [UIFont systemFontOfSize:22.0f];
    label.textColor = FlatBlack;
    label.textAlignment = NSTextAlignmentLeft;
    [self addSubview:label];
    
    return label;
}

@end
