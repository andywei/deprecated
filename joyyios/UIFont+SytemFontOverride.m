//
//  UIFont+SytemFontOverride.m
//  joyyios
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "UIFont+SytemFontOverride.h"

@implementation UIFont (SytemFontOverride)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

+ (UIFont *)systemFontOfSize:(CGFloat)size
{
    return [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:size];
}

+ (UIFont *)lightSystemFontOfSize:(CGFloat)size
{
    return [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:size];
}

+ (UIFont *)boldSystemFontOfSize:(CGFloat)size
{
    return [UIFont fontWithName:@"AvenirNextCondensed-Bold" size:size];
}

+ (UIFont *)preferredFontForTextStyle:(NSString *)style
{
    if ([style isEqualToString:UIFontTextStyleBody]) {
        return [UIFont systemFontOfSize:17];
    }

    if ([style isEqualToString:UIFontTextStyleHeadline]) {
        return [UIFont boldSystemFontOfSize:17];
    }

    if ([style isEqualToString:UIFontTextStyleSubheadline]) {
        return [UIFont systemFontOfSize:15];
    }

    if ([style isEqualToString:UIFontTextStyleFootnote]) {
        return [UIFont systemFontOfSize:13];
    }

    if ([style isEqualToString:UIFontTextStyleCaption1]) {
        return [UIFont systemFontOfSize:12];
    }

    if ([style isEqualToString:UIFontTextStyleCaption2]) {
        return [UIFont systemFontOfSize:11];
    }

    return [UIFont systemFontOfSize:17];
}

#pragma clang diagnostic pop

@end
