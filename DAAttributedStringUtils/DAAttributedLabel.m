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

@interface DATextLayer : CALayer
@property (strong,nonatomic) id string;
@property (strong,nonatomic) UIFont* font;
@property (strong,nonatomic) UIColor* textColor;
@end

@implementation DATextLayer
+ (id) layer
{
	DATextLayer* layer = [[DATextLayer alloc] init];
	layer.contentsGravity = kCAGravityBottomLeft;
	return layer;
}
- (void) drawInContext:(CGContextRef)ctx
{
	if ([self.string isKindOfClass:[NSAttributedString class]]) {
		CGContextSetTextMatrix(ctx, CGAffineTransformIdentity);
		CGContextTranslateCTM(ctx, self.bounds.origin.x, self.bounds.origin.y + self.bounds.size.height);
		CGContextScaleCTM(ctx, 1, -1);

		CGMutablePathRef path = CGPathCreateMutable();
		CGPathAddRect(path, NULL, self.bounds);

		CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.string);
		CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
		CFRelease(framesetter);
		CFRelease(path);

		CTFrameDraw(frame, ctx);
		CFRelease(frame);
	} else if ([self.string isKindOfClass:[NSString class]]) {
		NSString* str = self.string;
		UIGraphicsPushContext(ctx);
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0) && (__IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0)
		// Building with SDK 7.0+
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0
		// Targeting 7.0+
		[str drawInRect:self.bounds withAttributes:@{NSFontAttributeName:self.font, NSForegroundColorAttributeName:self.textColor}];
#else
		// Targeting <7.0+
		if ([[[UIDevice currentDevice] systemVersion] integerValue] < 7) {
			// Running on <7.0
			CGContextSetStrokeColorWithColor(ctx, self.textColor.CGColor);
			[str drawInRect:self.bounds withFont:self.font];
		} else {
			// running on 7.0+
			[str drawInRect:self.bounds withAttributes:@{NSFontAttributeName:self.font, NSForegroundColorAttributeName:self.textColor}];
		}
#endif
#else
		// Building with SDK <7.0 (deprecated)
		CGContextSetStrokeColorWithColor(ctx, self.textColor.CGColor);
		[str drawInRect:self.bounds withFont:self.font];
#endif
		UIGraphicsPopContext();
	}
}
@end

@interface DAAttributedLabelBaseLayer : DABoxesLayer
@end

@interface DAAttributedLabel ()
{
	NSArray* linkRanges;
	NSDictionary* linkBounds;
	NSMutableArray* linkLayers;
	NSInteger linkTouch;
	NSMutableArray* linkTouchLayers;
	BOOL linkTouchLayersInstalled;
	CALayer* linkTouchLayer1;
	CALayer* linkTouchLayer2;
	NSTimeInterval touchTimestamp;
	NSTimer* touchTimer;
	DATextLayer* textLayer;
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
		if ([layer isKindOfClass:[DATextLayer class]]) {
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
	touchTimer = nil;
	textLayer = [DATextLayer layer];
	[textLayer setNeedsDisplay];
	CGFloat scale = [[UIScreen mainScreen] scale];
	textLayer.contentsScale = scale;
	textLayer.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	textLayer.textColor = [UIColor blackColor];
	[self.layer addSublayer:textLayer];
	self.backgroundColor = [UIColor clearColor];
	linkRanges = nil;
	linkBounds = nil;
	linkTouch = -1;
	linkTouchLayers = nil;
	linkTouchLayersInstalled = NO;
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
	return textLayer.font;
}

- (void) setFont:(UIFont *)font
{
	if (font != textLayer.font) {
		textLayer.font = font;
		[textLayer setNeedsDisplay];
	}
}

- (UIColor*) textColor
{
	return textLayer.textColor;
}

- (void) setTextColor:(UIColor *)textColor
{
	if (textColor != textLayer.textColor) {
		textLayer.textColor = textColor;
		[textLayer setNeedsDisplay];
	}
}

- (id) text
{
	return textLayer.string;
}

- (void) setText:(id)text
{
	textLayer.string = text;
	[textLayer setNeedsDisplay];
	[self setupLinkBounds];
	[self setupBackgroundBoxes];
}

- (void) setText:(id)text withLinkRanges:(NSArray*)withLinkRanges
{
	textLayer.string = text;
	linkRanges = withLinkRanges;
	[textLayer setNeedsDisplay];
	[self setupLinkBounds];
	[self setupBackgroundBoxes];
}

- (DATextLayer*) textLayer
{
	return (DATextLayer*)self.layer;
}

- (CGSize)boundsForWidth:(CGFloat)inWidth withAttributedString:(NSAttributedString *)attributedString
{
	CFRange fitRange;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString( (__bridge CFMutableAttributedStringRef) attributedString);
    CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, CGSizeMake(inWidth, CGFLOAT_MAX), &fitRange);
    CFRelease(framesetter);
    return CGSizeMake(inWidth, suggestedSize.height);
}

- (void) setPreferredHeight
{
	CGSize preferredSize;
	if ([textLayer.string isKindOfClass:[NSString class]]) {
		NSString* str = textLayer.string;
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0) && (__IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0)
		// Building with SDK 7.0+
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0
		// Targeting 7.0+
		preferredSize = [str boundingRectWithSize:CGSizeMake(self.bounds.size.width, MAXFLOAT)
										  options:NSStringDrawingUsesLineFragmentOrigin
									   attributes:@{NSFontAttributeName:self.font}
										  context:nil].size;
#else
		// Targeting <7.0+
		if ([[[UIDevice currentDevice] systemVersion] integerValue] < 7) {
			// Running on <7.0
			preferredSize = [str sizeWithFont:self.font
							constrainedToSize:CGSizeMake(self.bounds.size.width, MAXFLOAT)
								lineBreakMode:NSLineBreakByWordWrapping];
		} else {
			// running on 7.0+
			preferredSize = [str boundingRectWithSize:CGSizeMake(self.bounds.size.width, MAXFLOAT)
											  options:NSStringDrawingUsesLineFragmentOrigin
										   attributes:@{NSFontAttributeName:self.font}
											  context:nil].size;
		}
#endif
#else
		// Building with SDK <7.0 (deprecated)
		preferredSize = [str sizeWithFont:self.font
						constrainedToSize:CGSizeMake(self.bounds.size.width, MAXFLOAT)
							lineBreakMode:NSLineBreakByWordWrapping];
#endif
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
	[textLayer setNeedsDisplay];
}

- (CGFloat) getPreferredHeight
{
	CGSize preferredSize = CGSizeMake(0.0f, 0.0f);
	if ([textLayer.string isKindOfClass:[NSString class]]) {
		NSString* str = textLayer.string;
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0) && (__IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0)
		// Building with SDK 7.0+
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0
		// Targeting 7.0+
		preferredSize = [str boundingRectWithSize:CGSizeMake(self.bounds.size.width, MAXFLOAT)
										  options:NSStringDrawingUsesLineFragmentOrigin
									   attributes:@{NSFontAttributeName:self.font}
										  context:nil].size;
#else
		// Targeting <7.0+
		if ([[[UIDevice currentDevice] systemVersion] integerValue] < 7) {
			// Running on <7.0
			preferredSize = [str sizeWithFont:self.font
							constrainedToSize:CGSizeMake(self.bounds.size.width, MAXFLOAT)
								lineBreakMode:NSLineBreakByWordWrapping];
		} else {
			// running on 7.0+
			preferredSize = [str boundingRectWithSize:CGSizeMake(self.bounds.size.width, MAXFLOAT)
											  options:NSStringDrawingUsesLineFragmentOrigin
										   attributes:@{NSFontAttributeName:self.font}
											  context:nil].size;
		}
#endif
#else
		// Building with SDK <7.0 (deprecated)
		preferredSize = [str sizeWithFont:self.font
						constrainedToSize:CGSizeMake(self.bounds.size.width, MAXFLOAT)
							lineBreakMode:NSLineBreakByWordWrapping];
#endif
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
	[textLayer setNeedsDisplay];
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
		NSMutableArray* boundsArr = [NSMutableArray array];
		BOOL foundRun = NO;
		for (CFIndex lineNum = 0; lineNum < numLines; lineNum++) {
			CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex(lines, lineNum);
			CFArrayRef runs = CTLineGetGlyphRuns(line);
			CFIndex numRuns = CFArrayGetCount(runs);
			CGRect totalRunBounds;
			CGPoint runPos;
			CGFloat ascent, descent;
			CTLineGetTypographicBounds(line, &ascent, &descent, nil);
			CGFloat additionalOffset = 0.0f;
			if ([[[UIDevice currentDevice] systemVersion] integerValue] < 6) {
				additionalOffset = -ascent;
			}
			totalRunBounds = CGRectZero;
			for (CFIndex runNum = 0; runNum < numRuns; runNum++) {
				CTRunRef run = CFArrayGetValueAtIndex(runs, runNum);
				if (CTRunGetStringRange(run).location == range.location) {
					CGContextSetTextPosition(ctx, origins[lineNum].x, origins[lineNum].y);
					CGRect runBounds = CTRunGetImageBounds(run, ctx, CFRangeMake(0, 0));
					CTRunGetPositions(run, CFRangeMake(0,1), &runPos);
					runBounds = CGRectMake(floor(runPos.x + origins[lineNum].x),
										   floor(self.bounds.size.height - origins[lineNum].y - ascent - additionalOffset),
										   ceil(runBounds.size.width + 2.0f),
										   ceil(ascent + descent));
					totalRunBounds = CGRectIsEmpty(totalRunBounds) ? runBounds : CGRectUnion(runBounds, totalRunBounds);
					NSUInteger runLength = CTRunGetStringRange(CFArrayGetValueAtIndex(runs, runNum)).length;
					range.location += runLength;
					range.length -= runLength;
					foundRun = YES;
				}
				if (range.length <= 0) break;
			}
			if (!CGRectIsEmpty(totalRunBounds)) {
				[boundsArr addObject:[NSValue valueWithCGRect:totalRunBounds]];
				[linkBoundsM setValue:boundsArr forKey:[NSString stringWithFormat:@"%ld", (long)linkNum]];
			} else if (foundRun) {
				break;
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
					runBounds = CGRectMake(floor(runPos.x + origins[lineNum].x),
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

- (BOOL) point:(CGPoint)point inLinkBounds:(NSArray*)linkBoundArr
{
	for (NSValue* rectValue in linkBoundArr) {
		if (CGRectContainsPoint([rectValue CGRectValue], point)) {
			return YES;
		}
	}
	return NO;
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (touchTimer != nil) {
		[self removeLinkTouchLayers:touchTimer.userInfo];
		[touchTimer invalidate];
		touchTimer = nil;
	}
	UITouch *touch = [touches anyObject];
	touchTimestamp = touch.timestamp;
	CGPoint point = [touch locationInView:self];
	for (NSString* linkNumKey in linkBounds.allKeys) {
		NSArray* linkBoundArr = [linkBounds valueForKey:linkNumKey];
		if ([self point:point inLinkBounds:linkBoundArr]) {
			linkTouch = [linkNumKey integerValue];
			[CATransaction begin];
			[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
			linkTouchLayers = [NSMutableArray array];
			for (NSValue* rectValue in linkBoundArr) {
				CALayer* linkTouchLayer = [CALayer layer];
				linkTouchLayer.cornerRadius = 3.0f;
				linkTouchLayer.backgroundColor = [UIColor blueColor].CGColor;
				linkTouchLayer.opacity = 0.3f;
				linkTouchLayer.frame = [rectValue CGRectValue];
				[linkTouchLayers addObject:linkTouchLayer];
				[self.layer addSublayer:linkTouchLayer];
			}
			[CATransaction commit];
			linkTouchLayersInstalled = YES;
			return;
		}
	}
	[super touchesBegan:touches withEvent:event];
}

- (void) removeLinkTouchLayers:(NSArray*)layers
{
	for (CALayer* linkTouchLayer in layers) {
		[linkTouchLayer removeFromSuperlayer];
	}
}

- (void) delayedRemoveLinkTouchLayers:(NSTimer*)timer
{
	touchTimer = nil;
	[self removeLinkTouchLayers:timer.userInfo];
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (linkTouch != -1) {
		linkTouch = -1;
		[self removeLinkTouchLayers:linkTouchLayers];
		linkTouchLayers = nil;
		linkTouchLayersInstalled = NO;
	} else {
		[super touchesCancelled:touches withEvent:event];
	}
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (linkTouch != -1) {
		UITouch *touch = [touches anyObject];
		if (linkTouchLayersInstalled) {
			if (_delegate != nil) {
				[_delegate label:self didSelectLink:linkTouch];
			}
		}
		linkTouch = -1;
		if ((touch.timestamp - touchTimestamp) < 0.2f) {
			touchTimer = [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(delayedRemoveLinkTouchLayers:) userInfo:linkTouchLayers repeats:NO];
		} else {
			[self removeLinkTouchLayers:linkTouchLayers];
		}
		linkTouchLayers = nil;
		linkTouchLayersInstalled = NO;
	} else {
		[super touchesEnded:touches withEvent:event];
	}
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (linkTouch != -1) {
		NSArray* linkBoundArr = [linkBounds valueForKey:[NSString stringWithFormat:@"%ld", (long)linkTouch]];
		UITouch *touch = [touches anyObject];
		CGPoint point = [touch locationInView:self];
		if ([self point:point inLinkBounds:linkBoundArr]) {
			if (!linkTouchLayersInstalled) {
				for (CALayer* linkTouchLayer in linkTouchLayers) {
					[self.layer addSublayer:linkTouchLayer];
				}
				linkTouchLayersInstalled = YES;
			}
		} else {
			if (linkTouchLayersInstalled) {
				[self removeLinkTouchLayers:linkTouchLayers];
				linkTouchLayersInstalled = NO;
			}
		}
	} else {
		[super touchesMoved:touches withEvent:event];
	}
}

@end
