//
//  DABoxesLayer.m
//  DAAttributedStringUtilsExample
//
//  Created by David Levi on 2/21/13.
//  Copyright (c) 2013 Double Apps Inc. All rights reserved.
//

#import "DABoxesLayer.h"

@implementation DABoxesLayer

- (void)drawInContext:(CGContextRef)ctx
{
	for (NSArray* box in _boxes) {
		CGRect rect = [[box objectAtIndex:0] CGRectValue];
		UIColor* color = (UIColor*)[box objectAtIndex:1];
		CGContextSetFillColorWithColor(ctx, color.CGColor);
		CGContextFillRect(ctx, rect);
	}
}

- (void) setBoxes:(NSArray *)boxes
{
	_boxes = boxes;
	[self setNeedsDisplay];
}

@end
