//
//  DAAttributedLabel.m
//  PrairieSchooner
//
//  Created by David Levi on 1/10/13.
//  Copyright (c) 2013 Double Apps Inc. All rights reserved.
//

#import "DAAttributedLabel.h"
#import <CoreText/CoreText.h>
#import "DAAttributedStringFormatter.h"

@interface DAAttributedLabel ()
{
	UIFont* _font;
	UIColor* _textColor;
	NSArray* linkRanges;
	NSDictionary* linkBounds;
	NSMutableArray* linkLayers;
	NSInteger linkTouch;
	CALayer* linkTouchLayer1;
	CALayer* linkTouchLayer2;
}
@property (readonly) CATextLayer* textLayer;
- (void) setupLinkBounds;
@end

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
	linkRanges = nil;
	linkBounds = nil;
	linkTouch = -1;
	linkTouchLayer1 = nil;
	linkTouchLayer2 = nil;
	self.layer.shouldRasterize = NO;
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

- (void) setText:(id)text withLinkRanges:(NSArray*)withLinkRanges
{
	self.textLayer.string = text;
	linkRanges = withLinkRanges;
	[self setupLinkBounds];
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
	[self setupLinkBounds];
}

- (void) layoutSubviews
{
	[self setupLinkBounds];
	[super layoutSubviews];
}

- (void) setupLinkBounds
{
	if (![self.textLayer.string isKindOfClass:[NSAttributedString class]]) {
		return;
	}
	NSAttributedString* str = self.textLayer.string;
	if (linkRanges == nil) {
		NSMutableArray* linkRangesM = [NSMutableArray array];
		[str enumerateAttribute:DALinkAttributeName
						inRange:NSMakeRange(0, str.length)
						options:0
					 usingBlock:^(id value, NSRange range, BOOL *stop) {
						 if (value != nil) {
							 [linkRangesM addObject:[NSValue valueWithRange:range]];
						 }
					 }];
		if (linkRangesM.count > 0) {
			linkRanges = [NSArray arrayWithArray:linkRangesM];
		}
		return;
	}
	
	NSMutableDictionary* linkBoundsM = [NSMutableDictionary dictionary];
	
	UIGraphicsBeginImageContext(self.bounds.size);
	CGContextRef ctx = UIGraphicsGetCurrentContext();

	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, self.bounds);
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString( (__bridge CFMutableAttributedStringRef) str);
	CTFrameRef textFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
	CFRelease(framesetter);
	CGPathRelease(path);

	CFArrayRef lines = CTFrameGetLines(textFrame);
	CFIndex numLines = CFArrayGetCount(lines);
	CGPoint origins[numLines];
	CTFrameGetLineOrigins(textFrame, CFRangeMake(0, numLines), origins);
	NSInteger linkNum = 0;
	for (NSValue* rangeVal in linkRanges) {
		NSRange range = [rangeVal rangeValue];
		BOOL foundRun = NO;
		for (CFIndex lineNum = 0; (lineNum < numLines) && !foundRun; lineNum++) {
			CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(lines, lineNum);
			CFArrayRef runs = CTLineGetGlyphRuns(line);
			CFIndex numRuns = CFArrayGetCount(runs);
			CGRect runBounds;
			CGPoint runPos;
			CGFloat ascent, descent;
			CTLineGetTypographicBounds(line, &ascent, &descent, nil);
			CGFloat additionalOffset = 0.0f;
			if ([[[UIDevice currentDevice] systemVersion] integerValue] < 6) {
				additionalOffset = descent;
			}
			for (CFIndex runNum = 0; (runNum < numRuns) && !foundRun; runNum++) {
				CTRunRef run = CFArrayGetValueAtIndex(runs, runNum);
				if (CTRunGetStringRange(run).location == range.location) {
					CGContextSetTextPosition(ctx, origins[lineNum].x, origins[lineNum].y);
					runBounds = CTRunGetImageBounds(run, ctx, CFRangeMake(0, 0));
					CTRunGetPositions(run, CFRangeMake(0,1), &runPos);
					runBounds = CGRectMake(floor(runPos.x),
										   floor(self.bounds.size.height - origins[lineNum].y - ascent - additionalOffset),
										   ceil(runBounds.size.width),
										   ceil(ascent + descent));
					NSArray* boundsArr = @[ [NSValue valueWithCGRect:runBounds] ];
					if (CTRunGetStringRange(CFArrayGetValueAtIndex(runs, runNum)).length != range.length) {
						if ((lineNum + 1) < numLines) {
							runs = CTLineGetGlyphRuns((CTLineRef)CFArrayGetValueAtIndex(lines, lineNum+1));
							run = CFArrayGetValueAtIndex(runs, 0);
							CGContextSetTextPosition(ctx, origins[lineNum+1].x, origins[lineNum+1].y);
							runBounds = CTRunGetImageBounds(run, ctx, CFRangeMake(0, 0));
							CTRunGetPositions(run, CFRangeMake(0,1), &runPos);
							runBounds = CGRectMake(floor(runPos.x),
												   floor(self.bounds.size.height - origins[lineNum+1].y - ascent - additionalOffset),
												   ceil(runBounds.size.width),
												   ceil(ascent + descent));
							boundsArr = @[ [boundsArr objectAtIndex:0], [NSValue valueWithCGRect:runBounds] ];
						}
					}
					[linkBoundsM setValue:boundsArr forKey:[NSString stringWithFormat:@"%d", linkNum]];
					foundRun = YES;
				}
			}
		}
		linkNum++;
	}
	
	CFRelease(textFrame);
	
	UIGraphicsEndImageContext();
	
	if (linkBoundsM.count == 0) {
		linkBounds = nil;
	} else {
		linkBounds = [NSDictionary dictionaryWithDictionary:linkBoundsM];
	}
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:self];
	for (NSString* linkNumKey in linkBounds.allKeys) {
		NSArray* linkBoundArr = [linkBounds valueForKey:linkNumKey];
		NSValue* linkBoundVal1 = [linkBoundArr objectAtIndex:0];
		NSValue* linkBoundVal2 = (linkBoundArr.count == 2) ? [linkBoundArr objectAtIndex:1] : nil;
		CGRect rect1 = [linkBoundVal1 CGRectValue];
		CGRect rect2 = (linkBoundVal2 != nil) ? [linkBoundVal2 CGRectValue] : CGRectNull;
		if (CGRectContainsPoint(rect1, point) || CGRectContainsPoint(rect2, point)) {
			linkTouch = [linkNumKey integerValue];
			if (linkTouchLayer1 == nil) {
				linkTouchLayer1 = [CALayer layer];
				linkTouchLayer1.cornerRadius = 3.0f;
				linkTouchLayer1.backgroundColor = [UIColor blueColor].CGColor;
				linkTouchLayer1.opacity = 0.3f;
			}
			if (linkTouchLayer2 == nil) {
				linkTouchLayer2 = [CALayer layer];
				linkTouchLayer2.cornerRadius = 3.0f;
				linkTouchLayer2.backgroundColor = [UIColor blueColor].CGColor;
				linkTouchLayer2.opacity = 0.3f;
			}
			[CATransaction begin];
			[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
			linkTouchLayer1.frame = rect1;
			if (linkBoundVal2 != nil) {
				linkTouchLayer2.frame = rect2;
			}
			[CATransaction commit];
			[self.layer addSublayer:linkTouchLayer1];
			if (linkBoundVal2 != nil) {
				[self.layer addSublayer:linkTouchLayer2];
			}
			return;
		}
	}
	[super touchesBegan:touches withEvent:event];
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (linkTouch != -1) {
		linkTouch = -1;
		[linkTouchLayer1 removeFromSuperlayer];
		[linkTouchLayer2 removeFromSuperlayer];
	} else {
		[super touchesCancelled:touches withEvent:event];
	}
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (linkTouch != -1) {
		if (linkTouchLayer1.superlayer != nil) {
			if (_delegate != nil) {
//				NSDictionary* linkBound = [linkBounds objectAtIndex:linkTouch];
//				NSInteger linkNum = [[linkBound valueForKey:@"link"] integerValue];
				[_delegate label:self didSelectLink:linkTouch];
			}
		}
		linkTouch = -1;
		[linkTouchLayer1 removeFromSuperlayer];
		[linkTouchLayer2 removeFromSuperlayer];
	} else {
		[super touchesEnded:touches withEvent:event];
	}
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (linkTouch != -1) {
		NSArray* linkBoundArr = [linkBounds valueForKey:[NSString stringWithFormat:@"%d", linkTouch]];
		NSValue* linkBoundVal1 = [linkBoundArr objectAtIndex:0];
		NSValue* linkBoundVal2 = (linkBoundArr.count == 2) ? [linkBoundArr objectAtIndex:1] : nil;
		CGRect rect1 = [linkBoundVal1 CGRectValue];
		CGRect rect2 = (linkBoundVal2 != nil) ? [linkBoundVal2 CGRectValue] : CGRectNull;
		UITouch *touch = [touches anyObject];
		CGPoint point = [touch locationInView:self];
		if (CGRectContainsPoint(rect1, point) || CGRectContainsPoint(rect2, point)) {
			if (linkTouchLayer1.superlayer == nil) {
				[self.layer addSublayer:linkTouchLayer1];
			}
			if (linkBoundVal2 != nil) {
				if (linkTouchLayer2.superlayer == nil) {
					[self.layer addSublayer:linkTouchLayer2];
				}
			}
		} else {
			if (linkTouchLayer1.superlayer != nil) {
				[linkTouchLayer1 removeFromSuperlayer];
			}
			if (linkTouchLayer2.superlayer != nil) {
				[linkTouchLayer2 removeFromSuperlayer];
			}
		}
	} else {
		[super touchesMoved:touches withEvent:event];
	}
}

@end
