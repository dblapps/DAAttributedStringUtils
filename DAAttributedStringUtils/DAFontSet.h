//
//  DAFontSet.h
//  PrairieSchooner
//
//  Created by David Levi on 1/11/13.
//  Copyright (c) 2013 Double Apps Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DAFontSet : NSObject
{
	NSDictionary* fontsDict;
	NSArray* fontsArray;
}

@property (readonly) NSString* name;

// Get a DAFontSet instance for a font family name.
+ (DAFontSet*) fontSetForFamily:(NSString*)familyName;

// Get a DAFontSet instance corresponding to an existing UIFont instance.
+ (DAFontSet*) fontSetForFont:(UIFont*)font;

// Get regular or italic UIFont instances with a particular size and weight, given a font family name
+ (UIFont*) fontWithFamily:(NSString*)familyName size:(CGFloat)size weight:(NSInteger)weight;
+ (UIFont*) fontWithFamily:(NSString*)familyName size:(CGFloat)size;
+ (UIFont*) italicFontWithFamily:(NSString*)familyName size:(CGFloat)size weight:(NSInteger)weight;
+ (UIFont*) italicFontWithFamily:(NSString*)familyName size:(CGFloat)size;

// Get regular or italic UIFont instances with a particular size and weight, given a UIFont instance
+ (UIFont*) fontWithFont:(UIFont*)font size:(CGFloat)size weight:(NSInteger)weight;
+ (UIFont*) fontWithFont:(UIFont*)font size:(CGFloat)size;
+ (UIFont*) italicFontWithFont:(UIFont*)font size:(CGFloat)size weight:(NSInteger)weight;
+ (UIFont*) italicFontWithFont:(UIFont*)font size:(CGFloat)size;

// Get regular or italic UIFont instances with a particular size and weight, given a DAFontSet instance
- (UIFont*) fontWithSize:(CGFloat)size weight:(NSInteger)weight;
- (UIFont*) fontWithSize:(CGFloat)size;
- (UIFont*) italicFontWithSize:(CGFloat)size weight:(NSInteger)weight;
- (UIFont*) italicFontWithSize:(CGFloat)size;

// Get a version of a font with a different specific weight
+ (UIFont*) changeWeightTo:(NSInteger)weight forFont:(UIFont*)font;

// Get a version of a font with a higher or smaller weight
+ (UIFont*) changeWeightBy:(NSInteger)weightChange forFont:(UIFont*)font;

// Get a regular version of a font
+ (UIFont*) regularFontForFont:(UIFont*)font;

// Get an italic version of a font
+ (UIFont*) italicFontForFont:(UIFont*)font;

@end
