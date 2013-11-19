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
#import "DABoxesLayer.h"

@interface DAAttributedLabelBaseLayer : DABoxesLayer
@end

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
	CATextLayer* textLayer;
}
- (void) setupLinkBounds;
- (void) setupBackgroundBoxes;
@end

@implementation DAAttributedLabelBaseLayer
- (void) layoutSublayers
{
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	for (CALayer* layer in self.sublayers) {
		if ([layer isKindOfClass:[CATextLayer class]]) {
			layer.frame = self.bounds;
		}
	}
	DAAttributedLabel* label = (DAAttributedLabel*)self.delegate;
	[label setupLinkBounds];
	[label setupBackgroundBoxes];
	[CATransaction commit];
}
@end

@implementation DAAttributedLabel

+ (id) layerClass
{
	return [DAAttributedLabelBaseLayer class];
}

- (void) initCommon
{
	textLayer = [CATextLayer layer];
	CGFloat scale = [[UIScreen mainScreen] scale];
	textLayer.contentsScale = scale;
	[self.layer addSublayer:textLayer];
	self.backgroundColor = [UIColor clearColor];
	_font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	textLayer.font = (__bridge CFTypeRef)(_font.fontName);
	textLayer.fontSize = _font.pointSize;
	_textColor = [UIColor blackColor];
	textLayer.foregroundColor = _textColor.CGColor;
	textLayer.wrapped = YES;
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
		textLayer.font = (__bridge CFTypeRef)(_font.fontName);
		textLayer.fontSize = _font.pointSize;
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
		textLayer.foregroundColor = _textColor.CGColor;
	}
}

- (id) text
{
	return textLayer.string;
}

- (void) setText:(id)text
{
	textLayer.string = text;
	[self setupLinkBounds];
	[self setupBackgroundBoxes];
}

- (void) setText:(id)text withLinkRanges:(NSArray*)withLinkRanges
{
	textLayer.string = text;
	linkRanges = withLinkRanges;
	[self setupLinkBounds];
	[self setupBackgroundBoxes];
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
	if ([textLayer.string isKindOfClass:[NSString class]]) {
		NSString* str = textLayer.string;
		preferredSize = [str sizeWithFont:_font constrainedToSize:CGSizeMake(self.bounds.size.width, 9999.0f) lineBreakMode:NSLineBreakByWordWrapping];
	} else if ([textLayer.string isKindOfClass:[NSAttributedString class]]) {
		NSAttributedString* str = textLayer.string;
		preferredSize = [self boundsForWidth:self.bounds.size.width withAttributedString:str];
	} else {
		return;
	}
	if (preferredSize.height != self.frame.size.height) {
		self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, preferredSize.height);
		[self setupLinkBounds];
		[self setupBackgroundBoxes];
	}
}

- (CGFloat) getPreferredHeight
{
	CGSize preferredSize = CGSizeMake(0.0f, 0.0f);
	if ([textLayer.string isKindOfClass:[NSString class]]) {
		NSString* str = textLayer.string;
		preferredSize = [str sizeWithFont:_font constrainedToSize:CGSizeMake(self.bounds.size.width, 9999.0f) lineBreakMode:NSLineBreakByWordWrapping];
	} else if ([textLayer.string isKindOfClass:[NSAttributedString class]]) {
		NSAttributedString* str = textLayer.string;
		preferredSize = [self boundsForWidth:self.bounds.size.width withAttributedString:str];
	}
	return preferredSize.height;
}

- (void) layoutSubviews
{
	[self setupLinkBounds];
	[self setupBackgroundBoxes];
	[super layoutSubviews];
}

- (void) setupLinkBounds
{
	if (![textLayer.string isKindOfClass:[NSAttributedString class]]) {
		return;
	}
	NSAttributedString* str = textLayer.string;
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
		} else {
			return;
		}
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
	if ([[[UIDevice currentDevice] systemVersion] integerValue] < 6) {
		CGFloat curY = 0.0f;
		CGFloat ascent, descent, leading;
		for (CFIndex lineNum = 0; lineNum < numLines; lineNum++) {
			origins[lineNum] = CGPointMake(0.0f, self.bounds.size.height - curY);
			CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(lines, lineNum);
			CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
			curY += ascent + descent;
		}
	} else {
		CTFrameGetLineOrigins(textFrame, CFRangeMake(0, numLines), origins);
	}
	
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
				additionalOffset = -ascent;
			}
			for (CFIndex runNum = 0; (runNum < numRuns) && !foundRun; runNum++) {
				CTRunRef run = CFArrayGetValueAtIndex(runs, runNum);
				if (CTRunGetStringRange(run).location == range.location) {
					CGContextSetTextPosition(ctx, origins[lineNum].x, origins[lineNum].y);
					runBounds = CTRunGetImageBounds(run, ctx, CFRangeMake(0, 0));
					CTRunGetPositions(run, CFRangeMake(0,1), &runPos);
					runBounds = CGRectMake(floor(runPos.x),
										   floor(self.bounds.size.height - origins[lineNum].y - ascent - additionalOffset),
										   ceil(runBounds.size.width + 2.0f),
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
												   ceil(runBounds.size.width + 2.0f),
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

- (void) setupBackgroundBoxes
{
	if (![textLayer.string isKindOfClass:[NSAttributedString class]]) {
		return;
	}

	NSAttributedString* str = textLayer.string;
	DABoxesLayer* boxesLayer = (DABoxesLayer*)self.layer;

	NSMutableArray* bgRanges = [NSMutableArray array];
	NSString* attrName = ([[[UIDevice currentDevice] systemVersion] integerValue] < 6) ? DABackgroundColorAttributeName : NSBackgroundColorAttributeName;
	[str enumerateAttribute:attrName
					inRange:NSMakeRange(0, str.length)
					options:0
				 usingBlock:^(id value, NSRange range, BOOL *stop) {
					 if (value != nil) {
						 if (CGColorGetAlpha((__bridge CGColorRef)value) != 0.0f) {
							 [bgRanges addObject:@[ [NSValue valueWithRange:range], [UIColor colorWithCGColor:(CGColorRef)value] ]];
						 }
					 }
				 }];
	if (bgRanges.count == 0) {
		boxesLayer.boxes = nil;
		return;
	}
	
	NSMutableArray* boxes = [NSMutableArray array];
	
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
	if ([[[UIDevice currentDevice] systemVersion] integerValue] < 6) {
		CGFloat curY = 0.0f;
		CGFloat ascent, descent, leading;
		for (CFIndex lineNum = 0; lineNum < numLines; lineNum++) {
			origins[lineNum] = CGPointMake(0.0f, self.bounds.size.height - curY);
			CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(lines, lineNum);
			CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
			curY += ascent + descent;
		}
	} else {
		CTFrameGetLineOrigins(textFrame, CFRangeMake(0, numLines), origins);
	}

	for (NSArray* bgRange in bgRanges) {
		NSValue* rangeVal = [bgRange objectAtIndex:0];
		NSRange range = [rangeVal rangeValue];
		UIColor* color = [bgRange objectAtIndex:1];
		BOOL foundRun = NO;
		for (CFIndex lineNum = 0; (lineNum < numLines) && !foundRun; lineNum++) {
			CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(lines, lineNum);
			CFArrayRef runs = CTLineGetGlyphRuns(line);
			CFIndex numRuns = CFArrayGetCount(runs);
			CGRect runBounds;
			CGPoint runPos;
			CGFloat ascent, descent, leading;
			CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
			CGFloat additionalOffset = 0.0f;
			if ([[[UIDevice currentDevice] systemVersion] integerValue] < 6) {
				additionalOffset = -ascent;
			}
			for (CFIndex runNum = 0; (runNum < numRuns) && !foundRun; runNum++) {
				CTRunRef run = CFArrayGetValueAtIndex(runs, runNum);
				CFRange cfRunRange = CTRunGetStringRange(run);
				NSRange runRange = { cfRunRange.location, cfRunRange.length };
				if (NSIntersectionRange(runRange, range).length > 0) {
					CGContextSetTextPosition(ctx, origins[lineNum].x, origins[lineNum].y);
					runBounds = CTRunGetImageBounds(run, ctx, CFRangeMake(0, 0));
					CTRunGetPositions(run, CFRangeMake(0,1), &runPos);
					runBounds = CGRectMake(floor(runPos.x),
										   floor(self.bounds.size.height - origins[lineNum].y - ascent - additionalOffset),
										   ceil(runBounds.size.width + 2.0f),
										   ceil(ascent + descent));
					[boxes addObject:@[ [NSValue valueWithCGRect:runBounds], color ]];
				}
			}
		}
	}
	
	CFRelease(textFrame);
	
	UIGraphicsEndImageContext();
	
	if (boxes.count > 0) {
		boxesLayer.boxes = [NSArray arrayWithArray:boxes];
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
