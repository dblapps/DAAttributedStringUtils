//
//  DAAttributedLabel.m
//  PrairieSchooner
//
//  Created by David Levi on 1/10/13.
//  Copyright (c) 2013 Double Apps Inc. All rights reserved.
//

#import "DAAttributedLabel.h"
#import <CoreText/CoreText.h>

@implementation DAAttributedLabel

+ (id) layerClass
{
	return [CATextLayer class];
}

- (void) initCommon
{
	self.backgroundColor = [UIColor clearColor];
	_font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	self.textLayer.font = (__bridge CFTypeRef)(_font.fontName);
	self.textLayer.fontSize = _font.pointSize;
	_textColor = [UIColor blackColor];
	self.textLayer.foregroundColor = _textColor.CGColor;
	self.textLayer.wrapped = YES;
}

- (id) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		[self initCommon];
	}
	return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self initCommon];
	}
	return self;
}

- (UIFont*) font
{
	return _font;
}

- (void) setFont:(UIFont *)font
{
	if (font != _font) {
		_font = font;
		self.textLayer.font = (__bridge CFTypeRef)(_font.fontName);
		self.textLayer.fontSize = _font.pointSize;
	}
}

- (UIColor*) textColor
{
	return _textColor;
}

- (void) setTextColor:(UIColor *)textColor
{
	if (textColor != _textColor) {
		_textColor = textColor;
		self.textLayer.foregroundColor = _textColor.CGColor;
	}
}

- (id) text
{
	return self.textLayer.string;
}

- (void) setText:(id)text
{
	self.textLayer.string = text;
}

- (CATextLayer*) textLayer
{
	return (CATextLayer*)self.layer;
}

- (CGSize)boundsForWidth:(CGFloat)inWidth withAttributedString:(NSAttributedString *)attributedString {
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString( (__bridge CFMutableAttributedStringRef) attributedString);
    CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, CGSizeMake(inWidth, CGFLOAT_MAX), NULL);
    CFRelease(framesetter);
    return CGSizeMake(inWidth, suggestedSize.height);
}

- (void) setPreferredHeight
{
	CGSize preferredSize;
	if ([self.textLayer.string isKindOfClass:[NSString class]]) {
		NSString* str = self.textLayer.string;
		preferredSize = [str sizeWithFont:_font constrainedToSize:CGSizeMake(self.bounds.size.width, 9999.0f) lineBreakMode:NSLineBreakByWordWrapping];
	} else if ([self.textLayer.string isKindOfClass:[NSAttributedString class]]) {
		NSAttributedString* str = self.textLayer.string;
		preferredSize = [self boundsForWidth:self.bounds.size.width withAttributedString:str];
	} else {
		return;
	}
	self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, preferredSize.height);
}

@end
