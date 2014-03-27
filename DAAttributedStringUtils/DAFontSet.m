//
//  DAFontSet.m
//  PrairieSchooner
//
//  Created by David Levi on 1/11/13.
//  Copyright (c) 2013 Double Apps Inc. All rights reserved.
//

#import "DAFontSet.h"

static NSDictionary* _fontSets = nil;


@interface DAFontPair : NSObject
@property (readonly) NSInteger weight;
@property (readonly) NSString* regular;
@property (readonly) NSString* italic;
- (instancetype) initWithWeight:(NSInteger)weight regular:(NSString*)regular italic:(NSString*)italic;
@end

@implementation DAFontPair
- (instancetype) initWithWeight:(NSInteger)weight regular:(NSString*)regular italic:(NSString*)italic
{
	self = [super init];
	if (self != nil) {
		_weight = weight;
		_regular = regular;
		_italic = italic;
	}
	return self;
}
@end


@interface DAFontSet ()
- (instancetype) initWithName:(NSString*)name pairsDict:(NSDictionary*)pairsDict pairsArray:(NSArray*)pairsArray;
- (DAFontPair*) fontPairForFont:(UIFont*)font;
- (DAFontPair*) fontPairForWeight:(NSInteger)weight;
@end

@implementation DAFontSet

+ (void) initialize
{
	static dispatch_once_t pred = 0;
	dispatch_once(&pred, ^{
		NSMutableDictionary* _fontSetsM = [NSMutableDictionary dictionary];
		NSString* plistFile = [[NSBundle mainBundle] pathForResource:@"DAFontSet" ofType:@"plist"];
		NSDictionary* fontSetsDict = [NSDictionary dictionaryWithContentsOfFile:plistFile];
		for (NSString* fontSetName in [fontSetsDict allKeys]) {
			NSMutableDictionary* fontSetMDictionary = [NSMutableDictionary dictionary];
			NSMutableArray* fontSetMArray = [NSMutableArray array];
			NSDictionary* fontSetDict = (NSDictionary*)[fontSetsDict valueForKey:fontSetName];
			for (NSString* fontPairWeight in [fontSetDict allKeys]) {
				NSArray* fontPairArray = [fontSetDict valueForKey:fontPairWeight];
				DAFontPair* fontPair = [[DAFontPair alloc] initWithWeight:[fontPairWeight integerValue]
																  regular:[fontPairArray objectAtIndex:0]
																   italic:[fontPairArray objectAtIndex:1]];
				[fontSetMDictionary setValue:fontPair forKey:fontPairWeight];
				[fontSetMArray addObject:fontPair];
			}
			DAFontSet* fontSet = [[DAFontSet alloc] initWithName:fontSetName pairsDict:fontSetMDictionary pairsArray:fontSetMArray];
			[_fontSetsM setValue:fontSet forKey:fontSetName];
		}
		_fontSets = [NSDictionary dictionaryWithDictionary:_fontSetsM];
	});
}

- (instancetype) initWithName:(NSString*)name pairsDict:(NSDictionary*)pairsDict pairsArray:(NSArray*)pairsArray
{
	self = [super init];
	if (self != nil) {
		_name = name;
		fontsDict = [NSDictionary dictionaryWithDictionary:pairsDict];
		fontsArray = [NSArray arrayWithArray:pairsArray];
	}
	return self;
}

- (DAFontPair*) fontPairForFont:(UIFont*)font
{
	for (DAFontPair* fontPair in fontsArray) {
		if ([fontPair.regular isEqualToString:font.fontName]) {
			return fontPair;
		}
		if ([fontPair.italic isEqualToString:font.fontName]) {
			return fontPair;
		}
	}
	return nil;
}

- (DAFontPair*) fontPairForWeight:(NSInteger)weight
{
	DAFontPair* fontPair = [fontsDict valueForKey:[NSString stringWithFormat:@"%ld", (long)weight]];
	if (fontPair == nil) {
		NSInteger offset = (weight < 0) ? 1 : -1;
		for (weight += offset; fontPair == nil; weight += offset) {
			fontPair = [fontsDict valueForKey:[NSString stringWithFormat:@"%ld", (long)weight]];
		}
	}
	return fontPair;
}

+ (DAFontSet*) fontSetForFamily:(NSString*)familyName
{
	return [_fontSets valueForKey:familyName];
}

+ (DAFontSet*) fontSetForFont:(UIFont*)font
{
	DAFontSet* fontSet = [_fontSets valueForKey:font.fontName];
	if (fontSet != nil) {
		return fontSet;
	}
	for (NSString* fontSetName in _fontSets) {
		fontSet = [_fontSets valueForKey:fontSetName];
		if ([fontSet fontPairForFont:font] != nil) {
			return fontSet;
		}
	}
	return nil;
}

+ (UIFont*) fontWithFamily:(NSString*)familyName size:(CGFloat)size weight:(NSInteger)weight
{
	DAFontSet* fontSet = [DAFontSet fontSetForFamily:familyName];
	if (fontSet == nil) {
		return nil;
	}
	return [fontSet fontWithSize:size weight:weight];
}

+ (UIFont*) fontWithFamily:(NSString*)familyName size:(CGFloat)size
{
	DAFontSet* fontSet = [DAFontSet fontSetForFamily:familyName];
	if (fontSet == nil) {
		return nil;
	}
	return [fontSet fontWithSize:size weight:0];
}

+ (UIFont*) italicFontWithFamily:(NSString*)familyName size:(CGFloat)size weight:(NSInteger)weight
{
	DAFontSet* fontSet = [DAFontSet fontSetForFamily:familyName];
	if (fontSet == nil) {
		return nil;
	}
	return [fontSet italicFontWithSize:size weight:weight];
}

+ (UIFont*) italicFontWithFamily:(NSString*)familyName size:(CGFloat)size
{
	DAFontSet* fontSet = [DAFontSet fontSetForFamily:familyName];
	if (fontSet == nil) {
		return nil;
	}
	return [fontSet italicFontWithSize:size weight:0];
}

+ (UIFont*) fontWithFont:(UIFont*)font size:(CGFloat)size weight:(NSInteger)weight
{
	return [[DAFontSet fontSetForFont:font] fontWithSize:size weight:weight];
}

+ (UIFont*) fontWithFont:(UIFont*)font size:(CGFloat)size
{
	return [UIFont fontWithName:[[DAFontSet fontSetForFont:font] fontPairForFont:font].regular size:size];
}

+ (UIFont*) italicFontWithFont:(UIFont*)font size:(CGFloat)size weight:(NSInteger)weight
{
	return [[DAFontSet fontSetForFont:font] italicFontWithSize:size weight:weight];
}

+ (UIFont*) italicFontWithFont:(UIFont*)font size:(CGFloat)size
{
	return [UIFont fontWithName:[[DAFontSet fontSetForFont:font] fontPairForFont:font].italic size:size];
}

- (UIFont*) fontWithSize:(CGFloat)size weight:(NSInteger)weight
{
	return [UIFont fontWithName:[self fontPairForWeight:weight].regular size:size];
}

- (UIFont*) fontWithSize:(CGFloat)size
{
	return [self fontWithSize:size weight:0];
}

- (UIFont*) italicFontWithSize:(CGFloat)size weight:(NSInteger)weight
{
	return [UIFont fontWithName:[self fontPairForWeight:weight].italic size:size];
}

- (UIFont*) italicFontWithSize:(CGFloat)size
{
	return [self italicFontWithSize:size weight:0];
}

+ (UIFont*) changeWeightTo:(NSInteger)weight forFont:(UIFont*)font
{
	DAFontSet* fontSet = [self fontSetForFont:font];
	DAFontPair* fontPair = [fontSet fontPairForFont:font];
	if ([fontPair.regular isEqualToString:font.fontName]) {
		return [fontSet fontWithSize:font.pointSize weight:weight];
	}
	return [fontSet italicFontWithSize:font.pointSize weight:weight];
}

+ (UIFont*) changeWeightBy:(NSInteger)weightChange forFont:(UIFont*)font
{
	DAFontSet* fontSet = [self fontSetForFont:font];
	DAFontPair* fontPair = [fontSet fontPairForFont:font];
	NSInteger weight = fontPair.weight + weightChange;
	if ([fontPair.regular isEqualToString:font.fontName]) {
		return [fontSet fontWithSize:font.pointSize weight:weight];
	}
	return [fontSet italicFontWithSize:font.pointSize weight:weight];
}

+ (UIFont*) regularFontForFont:(UIFont*)font
{
	DAFontSet* fontSet = [self fontSetForFont:font];
	DAFontPair* fontPair = [fontSet fontPairForFont:font];
	return [UIFont fontWithName:fontPair.regular size:font.pointSize];
}

+ (UIFont*) italicFontForFont:(UIFont*)font
{
	DAFontSet* fontSet = [self fontSetForFont:font];
	DAFontPair* fontPair = [fontSet fontPairForFont:font];
	return [UIFont fontWithName:fontPair.italic size:font.pointSize];
}

@end
