//
//  NSString+Joyy.h
//  joyyios
//
//  Created by Ping Yang on 4/12/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@interface NSString (Joyy)

+ (NSString *)agoStringForTimeInterval:(NSTimeInterval)interval;
+ (NSString *)apiURLWithPath:(NSString *)path;
+ (NSString *)e164PrefixForCountryCode:(NSString *)countryCode;

- (BOOL)isInvisible;
- (BOOL)isValidEmail;
- (BOOL)isAllDigits;

- (NSString *)messageDisplayString;
- (NSString *)messageMediaURL;
- (NSString *)personIdString;
- (NSUInteger)unsignedIntegerValue;


@end
