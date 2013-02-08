//
//  DAAttributedLabel.m
//  PrairieSchooner
//
//  Created by David Levi on 1/10/13.
//  Copyright (c) 2013 Double Apps Inc. All rights reserved.
//

#import "DAAttributedLabel.h"
#import <CoreText/CoreText.h>

@interface DAAttributedLabel ()
{
	NSArray* linkRanges;
	NSArray* linkBounds;
	NSMutableArray* linkLayers;
	NSInteger linkTouch;
	CALayer* linkTouchLayer;
}
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
	linkTouchLayer = nil;
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
	if (linkRanges == nil) {
		return;
	}
	
	NSMutableArray* linkBoundsM = [NSMutableArray array];
	
	UIGraphicsBeginImageContext(self.bounds.size);
	CGContextRef ctx = UIGraphicsGetCurrentContext();

	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, self.bounds);
	NSAttributedString* str = self.textLayer.string;
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
			for (CFIndex runNum = 0; (runNum < numRuns) && !foundRun; runNum++) {
				CTRunRef run = CFArrayGetValueAtIndex(runs, runNum);
				if (CTRunGetStringRange(run).location == range.location) {
					CGContextSetTextPosition(ctx, origins[lineNum].x, origins[lineNum].y);
					runBounds = CTRunGetImageBounds(run, ctx, CFRangeMake(0, 0));
					CTRunGetPositions(run, CFRangeMake(0,1), &runPos);
					runBounds = CGRectMake(floor(runPos.x),
										   floor(self.bounds.size.height - runBounds.origin.y - runBounds.size.height),
										   ceil(runBounds.size.width),
										   ceil(runBounds.size.height));
					NSDictionary* bounds = @{ @"link": [NSNumber numberWithInteger:linkNum], @"rect": [NSValue valueWithCGRect:runBounds] };
					[linkBoundsM addObject:bounds];
					if (CTRunGetStringRange(CFArrayGetValueAtIndex(runs, runNum)).length != range.length) {
						if ((lineNum + 1) < numLines) {
							runs = CTLineGetGlyphRuns((CTLineRef)CFArrayGetValueAtIndex(lines, lineNum+1));
							run = CFArrayGetValueAtIndex(runs, 0);
							CGContextSetTextPosition(ctx, origins[lineNum+1].x, origins[lineNum+1].y);
							runBounds = CTRunGetImageBounds(run, ctx, CFRangeMake(0, 0));
							CTRunGetPositions(run, CFRangeMake(0,1), &runPos);
							runBounds = CGRectMake(floor(runPos.x),
												   floor(self.bounds.size.height - runBounds.origin.y - runBounds.size.height),
												   ceil(runBounds.size.width),
												   ceil(runBounds.size.height));
							NSDictionary* bounds = @{ @"link": [NSNumber numberWithInteger:linkNum], @"rect": [NSValue valueWithCGRect:runBounds] };
							[linkBoundsM addObject:bounds];
						}
					}
					foundRun = YES;
				}
			}
		}
		linkNum++;
	}
	
	CFRelease(textFrame);
	
	UIGraphicsEndImageContext();
	
	linkBounds = [NSArray arrayWithArray:linkBoundsM];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:self];
	NSInteger linkBoundNum = 0;
	for (NSDictionary* linkBound in linkBounds) {
		CGRect rect = [[linkBound valueForKey:@"rect"] CGRectValue];
		if (CGRectContainsPoint(rect, point)) {
			linkTouch = linkBoundNum;
			if (linkTouchLayer == nil) {
				linkTouchLayer = [CALayer layer];
				linkTouchLayer.cornerRadius = 3.0f;
				linkTouchLayer.backgroundColor = [UIColor blueColor].CGColor;
				linkTouchLayer.opacity = 0.3f;
			}
			[CATransaction begin];
			[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
			linkTouchLayer.frame = rect;
			[CATransaction commit];
			[self.layer addSublayer:linkTouchLayer];
			return;
		}
		linkBoundNum++;
	}
	[super touchesBegan:touches withEvent:event];
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (linkTouch != -1) {
		linkTouch = -1;
		[linkTouchLayer removeFromSuperlayer];
	} else {
		[super touchesCancelled:touches withEvent:event];
	}
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (linkTouch != -1) {
		if (linkTouchLayer.superlayer != nil) {
			if (_delegate != nil) {
				NSDictionary* linkBound = [linkBounds objectAtIndex:linkTouch];
				NSInteger linkNum = [[linkBound valueForKey:@"link"] integerValue];
				[_delegate label:self didSelectLink:linkNum];
			}
		}
		linkTouch = -1;
		[linkTouchLayer removeFromSuperlayer];
	} else {
		[super touchesEnded:touches withEvent:event];
	}
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (linkTouch != -1) {
		NSDictionary* linkBound = [linkBounds objectAtIndex:linkTouch];
		UITouch *touch = [touches anyObject];
		CGPoint point = [touch locationInView:self];
		CGRect rect = [[linkBound valueForKey:@"rect"] CGRectValue];
		if (CGRectContainsPoint(rect, point)) {
			if (linkTouchLayer.superlayer == nil) {
				[self.layer addSublayer:linkTouchLayer];
			}
		} else {
			if (linkTouchLayer.superlayer != nil) {
				[linkTouchLayer removeFromSuperlayer];
			}
		}
	} else {
		[super touchesMoved:touches withEvent:event];
	}
}

@end
