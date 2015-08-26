//
//  NSAttributedString+DAAttributedStringUtils.m
//  DAAttributedStringUtilsExample
//
//  Created by David Levi on 8/26/15.
//  Copyright (c) 2015 Double Apps Inc. All rights reserved.
//

#import "NSAttributedString+DAAttributedStringUtils.h"
#import <CoreText/CoreText.h>

@implementation NSAttributedString (DAAttributedStringUtils)

- (CGSize) frameSizeThatFits:(CGSize)size
{
	CGSize frameSize = CGSizeMake(0.0f, 0.0f);
	CFRange fitRange;
	CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFMutableAttributedStringRef)self);
	frameSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, size, &fitRange);
	CFRelease(framesetter);
	return frameSize;
}

@end
