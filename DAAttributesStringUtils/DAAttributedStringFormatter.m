//
//  NSAttributedStringFormatter.m
//  PrairieSchooner
//
//  Created by David Levi on 1/11/13.
//  Copyright (c) 2013 Double Apps Inc. All rights reserved.
//

#import "DAAttributedStringFormatter.h"
#import <CoreText/CoreText.h>
#import "DAFontSet.h"

@implementation DAAttributedStringFormatter

@synthesize defaultPointSize;
@synthesize defaultFontFamily;
@synthesize defaultColor;
@synthesize fontFamilies;
@synthesize colors;

- (instancetype) init
{
	self = [super init];
	if (self != nil) {
		defaultPointSize = 17.0f;
		defaultFontFamily = @"Helvetica";
		defaultColor = [UIColor blackColor];
		fontFamilies = [NSArray array];
		colors = [NSArray array];
	}
	return self;
}

- (void) addFontAttr:(NSMutableArray*)attrs mcn:(NSUInteger)mcn font:(UIFont*)curFont fontArs:(NSUInteger)curFontArs
{
	if (curFontArs != NSNotFound) {
		NSRange range = { curFontArs, mcn - curFontArs };
		if (range.length > 0) {
			if ([[[UIDevice currentDevice] systemVersion] integerValue] < 6) {
				CTFontRef ctFont = CTFontCreateWithName((__bridge CFStringRef)curFont.fontName, curFont.pointSize, NULL);
				NSDictionary* attrDict = @{ (id)kCTFontAttributeName: (id)CFBridgingRelease(ctFont) };
				[attrs addObject:@[attrDict, [NSValue valueWithRange:range]]];
				CFRelease(ctFont);
			} else {
				NSDictionary* attrDict = @{ NSFontAttributeName: curFont };
				[attrs addObject:@[attrDict, [NSValue valueWithRange:range]]];
			}
		}
	}
}

- (void) addUnderlineAttr:(NSMutableArray*)attrs mcn:(NSUInteger)mcn underline:(CTUnderlineStyle)curUnderline underlineArs:(NSUInteger)curUnderlineArs
{
	if (curUnderlineArs != NSNotFound) {
		NSRange range = { curUnderlineArs, mcn - curUnderlineArs };
		if (range.length > 0) {
			if ([[[UIDevice currentDevice] systemVersion] integerValue] < 6) {
				CFNumberRef ctUnderlineNum = CFNumberCreate(NULL, kCFNumberSInt32Type, &curUnderline);
				NSDictionary* attrDict = @{ (id)kCTUnderlineStyleAttributeName: (id)CFBridgingRelease(ctUnderlineNum) };
				[attrs addObject:@[attrDict, [NSValue valueWithRange:range]]];
				CFRelease(ctUnderlineNum);
			} else {
				NSDictionary* attrDict = @{ NSUnderlineStyleAttributeName: [NSNumber numberWithInteger:curUnderline] };
				[attrs addObject:@[attrDict, [NSValue valueWithRange:range]]];
			}
		}
	}
}

- (void) addColorAttr:(NSMutableArray*)attrs mcn:(NSUInteger)mcn color:(UIColor*)curColor colorArs:(NSUInteger)curColorArs
{
	if (curColorArs != NSNotFound) {
		NSRange range = { curColorArs, mcn - curColorArs };
		if (range.length > 0) {
			if ([[[UIDevice currentDevice] systemVersion] integerValue] < 6) {
				NSDictionary* attrDict = @{ (id)kCTForegroundColorAttributeName: (id)curColor.CGColor };
				[attrs addObject:@[attrDict, [NSValue valueWithRange:range]]];
			} else {
				NSDictionary* attrDict = @{ NSForegroundColorAttributeName: (id)curColor.CGColor };
				[attrs addObject:@[attrDict, [NSValue valueWithRange:range]]];
			}
		}
	}
}

- (NSAttributedString*) formatString:(NSString*)format;
{
	UIFont* font = [DAFontSet fontWithFamily:defaultFontFamily size:defaultPointSize];
	NSMutableArray* fonts = [NSMutableArray arrayWithCapacity:fontFamilies.count];
	for (NSString* fontFamily in fontFamilies) {
		[fonts addObject:[DAFontSet fontWithFamily:fontFamily size:defaultPointSize]];
	}
	
	NSMutableString* mformat = [NSMutableString stringWithCapacity:format.length];
	NSMutableArray* attrs = [NSMutableArray array];
	
	BOOL haveFormatter = NO;
	BOOL gotDigit = NO;
	NSInteger sign = 1;
	NSUInteger mcn = 0;
	NSInteger value = 0;
	
	static CTUnderlineStyle underlineStyles[3] = { kCTUnderlineStyleNone, kCTUnderlineStyleSingle, kCTUnderlineStyleDouble };
	CTUnderlineStyle curUnderline = kCTUnderlineStyleNone;
	NSUInteger curUnderlineArs = NSNotFound;
	
	UIColor* curColor = defaultColor;
	NSUInteger curColorArs = NSNotFound;
	
	NSString* curFontFamily = defaultFontFamily;
	NSInteger curWeight = 0;
	UIFont* curFont = font;
	NSUInteger curFontArs = NSNotFound;
	
	BOOL italicOn = NO;
	
	for (NSUInteger cn = 0; cn < format.length; cn++) {
		unichar ch = [format characterAtIndex:cn];
		if (haveFormatter) {
			if ((ch >= '0') && (ch <= '9')) {
				gotDigit = YES;
				value = (value * 10) + ((NSInteger)(ch - '0'));
				continue;
			} else if (ch == '-') {
				if (gotDigit) {
					return nil;
				}
				sign = -1;
				continue;
			} else if (ch == 'B') {
				[self addFontAttr:attrs mcn:mcn font:curFont fontArs:curFontArs];
				curWeight = 1;
				curFont = [DAFontSet changeWeightTo:1 forFont:curFont];
				curFontArs = [font isEqual:curFont] ? NSNotFound : mcn;
			} else if (ch == 'b') {
				[self addFontAttr:attrs mcn:mcn font:curFont fontArs:curFontArs];
				curWeight = 0;
				curFont = [DAFontSet changeWeightTo:0 forFont:curFont];
				curFontArs = [font isEqual:curFont] ? NSNotFound : mcn;
			} else if (ch == 'W') {
				[self addFontAttr:attrs mcn:mcn font:curFont fontArs:curFontArs];
				curWeight = value*sign;
				curFont = [DAFontSet changeWeightTo:value*sign forFont:curFont];
				curFontArs = [font isEqual:curFont] ? NSNotFound : mcn;
			} else if (ch == 'I') {
				[self addFontAttr:attrs mcn:mcn font:curFont fontArs:curFontArs];
				italicOn = YES;
				curFont = [DAFontSet italicFontForFont:curFont];
				curFontArs = [font isEqual:curFont] ? NSNotFound : mcn;
			} else if (ch == 'i') {
				[self addFontAttr:attrs mcn:mcn font:curFont fontArs:curFontArs];
				italicOn = NO;
				curFont = [DAFontSet regularFontForFont:curFont];
				curFontArs = [font isEqual:curFont] ? NSNotFound : mcn;
			} else if (ch == 'F') {
				if (value >= fonts.count) {
					return nil;
				}
				[self addFontAttr:attrs mcn:mcn font:curFont fontArs:curFontArs];
				UIFont* newFont = [fonts objectAtIndex:value];
				curFontFamily = [fontFamilies objectAtIndex:value];
				if (italicOn) {
					curFont = [DAFontSet italicFontWithFont:newFont size:curFont.pointSize weight:curWeight];
				} else {
					curFont = [DAFontSet fontWithFont:newFont size:curFont.pointSize weight:curWeight];
				}
				curFontArs = [font isEqual:curFont] ? NSNotFound : mcn;
			} else if (ch == 'f') {
				[self addFontAttr:attrs mcn:mcn font:curFont fontArs:curFontArs];
				curFontFamily = defaultFontFamily;
				if (italicOn) {
					curFont = [DAFontSet italicFontWithFont:font size:curFont.pointSize weight:curWeight];
				} else {
					curFont = [DAFontSet fontWithFont:font size:curFont.pointSize weight:curWeight];
				}
				curFontArs = [font isEqual:curFont] ? NSNotFound : mcn;
			} else if (ch == 'S') {
				[self addFontAttr:attrs mcn:mcn font:curFont fontArs:curFontArs];
				if (italicOn) {
					curFont = [[DAFontSet fontSetForFont:curFont] italicFontWithSize:(CGFloat)value weight:curWeight];
				} else {
					curFont = [[DAFontSet fontSetForFont:curFont] fontWithSize:(CGFloat)value weight:curWeight];
				}
				curFontArs = [font isEqual:curFont] ? NSNotFound : mcn;
			} else if (ch == 's') {
				[self addFontAttr:attrs mcn:mcn font:curFont fontArs:curFontArs];
				if (italicOn) {
					curFont = [[DAFontSet fontSetForFont:curFont] italicFontWithSize:defaultPointSize weight:curWeight];
				} else {
					curFont = [[DAFontSet fontSetForFont:curFont] fontWithSize:defaultPointSize weight:curWeight];
				}
				curFontArs = [font isEqual:curFont] ? NSNotFound : mcn;
			} else if (ch == 'N') {
				[self addFontAttr:attrs mcn:mcn font:curFont fontArs:curFontArs];
				[self addUnderlineAttr:attrs mcn:mcn underline:curUnderline underlineArs:curUnderlineArs];
				italicOn = NO;
				curWeight = 0;
				curUnderline = kCTUnderlineStyleNone;
				curUnderlineArs = NSNotFound;
				curFontFamily = defaultFontFamily;
				curFont = [DAFontSet fontWithFont:font size:curFont.pointSize];
				curFontArs = NSNotFound;
			} else if (ch == 'U') {
				if (value > 2) {
					return nil;
				}
				[self addUnderlineAttr:attrs mcn:mcn underline:curUnderline underlineArs:curUnderlineArs];
				curUnderline = underlineStyles[value];
				curUnderlineArs = mcn;
			} else if (ch == 'u') {
				[self addUnderlineAttr:attrs mcn:mcn underline:curUnderline underlineArs:curUnderlineArs];
				curUnderline = kCTUnderlineStyleNone;
				curUnderlineArs = NSNotFound;
			} else if (ch == 'C') {
				if (value >= colors.count) {
					return nil;
				}
				[self addColorAttr:attrs mcn:mcn color:curColor colorArs:curColorArs];
				curColor = [colors objectAtIndex:value];
				curColorArs = ([defaultColor isEqual:curColor]) ? NSNotFound : mcn;
			} else if (ch == 'c') {
				[self addColorAttr:attrs mcn:mcn color:curColor colorArs:curColorArs];
				curColor = defaultColor;
				curColorArs = NSNotFound;
			} else {
				[mformat appendString:[NSString stringWithCharacters:&ch length:1]];
				mcn++;
			}
			haveFormatter = NO;
			gotDigit = NO;
			value = 0;
			sign = 1;
		} else {
			if (ch == '%') {
				haveFormatter = YES;
				gotDigit = NO;
				value = 0;
				sign = 1;
			} else {
				[mformat appendString:[NSString stringWithCharacters:&ch length:1]];
				mcn++;
			}
		}
	}
	[self addFontAttr:attrs mcn:mcn font:curFont fontArs:curFontArs];
	[self addUnderlineAttr:attrs mcn:mcn underline:curUnderline underlineArs:curUnderlineArs];
	
	NSMutableAttributedString* attrStr;
	if ([[[UIDevice currentDevice] systemVersion] integerValue] < 6) {
		CTFontRef ctFont = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
		NSDictionary* attrsDict = @{
			(id)kCTFontAttributeName: (id)CFBridgingRelease(ctFont),
			(id)kCTForegroundColorAttributeName: (id)defaultColor.CGColor
		};
		attrStr = [[NSMutableAttributedString alloc] initWithString:mformat attributes:attrsDict];
		CFRelease(ctFont);
	} else {
		NSDictionary* attrsDict = @{
			NSFontAttributeName: font,
			NSForegroundColorAttributeName: (id)defaultColor.CGColor
		};
		attrStr = [[NSMutableAttributedString alloc] initWithString:mformat attributes:attrsDict];
	}
	for (NSArray* attr in attrs) {
		NSDictionary* attrDict = [attr objectAtIndex:0];
		NSValue* rangeVal = [attr objectAtIndex:1];
		[attrStr addAttributes:attrDict range:[rangeVal rangeValue]];
	}
	
	return [[NSAttributedString alloc] initWithAttributedString:attrStr];
}

@end
