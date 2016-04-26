//
//  JYFloatLabeledTextField.m
//  joyyios
//
//  Forked and modified by Ping Yang on 3/26/15 from Github project: JVFloatLabeledTextField
//  Below is the original license:

//  The MIT License (MIT)
//
//  Copyright (c) 2013-2015 Jared Verdi
//  Original Concept by Matt D. Smith
//  http://dribbble.com/shots/1254439--GIF-Mobile-Form-Interaction?list=users
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//  ---------------------------The end of the original license--------------------

#import "JYFloatLabeledTextField.h"
#import "NSString+TextDirectionality.h"

#define kFloatingLabelShowAnimationDuration 0.3f
#define kFloatingLabelHideAnimationDuration 0.3f

@implementation JYFloatLabeledTextField

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self _commonInit];
    }
    return self;
}

- (void)_commonInit
{
    _floatingLabel = [UILabel new];
    _floatingLabel.alpha = 0.0f;
    [self addSubview:_floatingLabel];

    // some basic default fonts/colors
    _floatingLabelFont = [UIFont boldSystemFontOfSize:12.0f];
    _floatingLabel.font = _floatingLabelFont;
    _floatingLabelTextColor = FlatGreen;
    _floatingLabelInvalidTextColor = JoyyRed;
    _floatingLabel.textColor = _floatingLabelTextColor;
    _animateEvenIfNotFirstResponder = 0;
    _floatingLabelShowAnimationDuration = kFloatingLabelShowAnimationDuration;
    _floatingLabelHideAnimationDuration = kFloatingLabelHideAnimationDuration;
    [self setFloatingLabelText:self.placeholder];

    self.clearButtonMode = UITextFieldViewModeWhileEditing;
    _adjustsClearButtonRect = 1;
}

#pragma mark -

- (UIColor *)labelActiveColor
{
    if (_floatingLabelActiveTextColor)
    {
        return _floatingLabelActiveTextColor;
    }
    else if ([self respondsToSelector:@selector(tintColor)])
    {
        return [self performSelector:@selector(tintColor)];
    }

    return [UIColor blueColor];
}

- (void)setFloatingLabelFont:(UIFont *)floatingLabelFont
{
    _floatingLabelFont = floatingLabelFont;
    _floatingLabel.font = (_floatingLabelFont ? _floatingLabelFont : [UIFont boldSystemFontOfSize:12.0f]);
    [self setFloatingLabelText:self.placeholder];
    [self invalidateIntrinsicContentSize];
}

- (void)showFloatingLabel:(BOOL)animated
{
    __weak typeof(self) weakSelf = self;
    void (^showBlock)() = ^{
        weakSelf.floatingLabel.alpha = 1.0f;
        weakSelf.floatingLabel.frame = CGRectMake(weakSelf.floatingLabel.frame.origin.x, weakSelf.floatingLabelYPadding,
                                                  weakSelf.floatingLabel.frame.size.width, weakSelf.floatingLabel.frame.size.height);
    };

    if (animated || 0 != _animateEvenIfNotFirstResponder)
    {
        [UIView animateWithDuration:_floatingLabelShowAnimationDuration
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
                         animations:showBlock
                         completion:nil];
    }
    else
    {
        showBlock();
    }
}

- (void)hideFloatingLabel:(BOOL)animated
{
    __weak typeof(self) weakSelf = self;
    void (^hideBlock)() = ^{
        weakSelf.floatingLabel.alpha = 0.0f;
        weakSelf.floatingLabel.frame =
            CGRectMake(weakSelf.floatingLabel.frame.origin.x, weakSelf.floatingLabel.font.lineHeight + weakSelf.placeholderYPadding,
                       weakSelf.floatingLabel.frame.size.width, weakSelf.floatingLabel.frame.size.height);

    };

    if (animated || 0 != _animateEvenIfNotFirstResponder)
    {
        [UIView animateWithDuration:_floatingLabelHideAnimationDuration
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                         animations:hideBlock
                         completion:nil];
    }
    else
    {
        hideBlock();
    }
}

- (void)setLabelOriginForTextAlignment
{
    CGRect textRect = [self textRectForBounds:self.bounds];

    CGFloat originX = textRect.origin.x;

    if (self.textAlignment == NSTextAlignmentCenter)
    {
        originX = textRect.origin.x + (textRect.size.width / 2) - (_floatingLabel.frame.size.width / 2);
    }
    else if (self.textAlignment == NSTextAlignmentRight)
    {
        originX = textRect.origin.x + textRect.size.width - _floatingLabel.frame.size.width;
    }
    else if (self.textAlignment == NSTextAlignmentNatural)
    {
        JVTextDirection baseDirection = [_floatingLabel.text getBaseDirection];
        if (baseDirection == JVTextDirectionRightToLeft)
        {
            originX = textRect.origin.x + textRect.size.width - _floatingLabel.frame.size.width;
        }
    }

    _floatingLabel.frame = CGRectMake(originX, _floatingLabel.frame.origin.y, _floatingLabel.frame.size.width, _floatingLabel.frame.size.height);
}

- (void)setFloatingLabelText:(NSString *)text
{
    _floatingLabel.text = text;
    [self setNeedsLayout];
}

#pragma mark - UITextField

- (CGSize)intrinsicContentSize
{
    CGSize textFieldIntrinsicContentSize = [super intrinsicContentSize];
    return CGSizeMake(textFieldIntrinsicContentSize.width,
                      textFieldIntrinsicContentSize.height + _floatingLabelYPadding + _floatingLabel.font.lineHeight);
}

- (void)setPlaceholder:(NSString *)placeholder
{
    [super setPlaceholder:placeholder];
    [self setFloatingLabelText:placeholder];
}

- (void)setAttributedPlaceholder:(NSAttributedString *)attributedPlaceholder
{
    [super setAttributedPlaceholder:attributedPlaceholder];
    [self setFloatingLabelText:attributedPlaceholder.string];
}

- (void)setPlaceholder:(NSString *)placeholder floatingTitle:(NSString *)floatingTitle
{
    [super setPlaceholder:placeholder];
    [self setFloatingLabelText:floatingTitle];
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
    CGRect rect = [super textRectForBounds:bounds];
    if ([self.text length])
    {
        CGFloat topInset = ceilf(_floatingLabel.font.lineHeight + _placeholderYPadding);
        topInset = MIN(topInset, [self _maxTopInset]);
        rect = UIEdgeInsetsInsetRect(rect, UIEdgeInsetsMake(topInset, 0.0f, 0.0f, 0.0f));
    }
    return CGRectIntegral(rect);
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    CGRect rect = [super editingRectForBounds:bounds];
    if ([self.text length])
    {
        CGFloat topInset = ceilf(_floatingLabel.font.lineHeight + _placeholderYPadding);
        topInset = MIN(topInset, [self _maxTopInset]);
        rect = UIEdgeInsetsInsetRect(rect, UIEdgeInsetsMake(topInset, 0.0f, 0.0f, 0.0f));
    }
    return CGRectIntegral(rect);
}

- (CGRect)clearButtonRectForBounds:(CGRect)bounds
{
    CGRect rect = [super clearButtonRectForBounds:bounds];
    if (0 != self.adjustsClearButtonRect)
    {
        if ([self.text length])
        {
            CGFloat topInset = ceilf(_floatingLabel.font.lineHeight + _placeholderYPadding);
            topInset = MIN(topInset, [self _maxTopInset]);
            rect = CGRectMake(rect.origin.x, rect.origin.y + topInset / 2.0f, rect.size.width, rect.size.height);
        }
    }
    return CGRectIntegral(rect);
}

- (CGFloat)_maxTopInset
{
    return MAX(0, floorf(self.bounds.size.height - self.font.lineHeight - 4.0f));
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
    [super setTextAlignment:textAlignment];
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self setLabelOriginForTextAlignment];

    if (self.floatingLabelFont)
    {
        _floatingLabel.font = self.floatingLabelFont;
    }

    [_floatingLabel sizeToFit];

    BOOL firstResponder = self.isFirstResponder;
    _floatingLabel.textColor = (firstResponder && self.text && self.text.length > 0 ? self.labelActiveColor : self.floatingLabelTextColor);

    if (firstResponder && self.text && self.text.length > 0)
    {
        _floatingLabel.textColor = self.labelActiveColor;
    }
    else if ([self _isValidText])
    {
        _floatingLabel.textColor = self.floatingLabelTextColor;
    }
    else
    {
        _floatingLabel.textColor = self.floatingLabelInvalidTextColor;
    }

    if (!self.text || 0 == [self.text length])
    {
        [self hideFloatingLabel:firstResponder];
    }
    else
    {
        [self showFloatingLabel:firstResponder];
    }
}

#pragma mark - Validation

- (BOOL)_isValidText
{
    BOOL result = YES;
    switch (self.autocompleteType)
    {
        case JYAutoCompleteTypeEmail:
            result = self.text && [self.text isValidEmail];
            break;
        default:
            break;
    }

    return result;
}

@end