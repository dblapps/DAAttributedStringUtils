//
//  DABoxesLayer.h
//  DAAttributedStringUtilsExample
//
//  Created by David Levi on 2/21/13.
//  Copyright (c) 2013 Double Apps Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface DABoxesLayer : CALayer

// boxes must be an array of arrays, where each element contains two elements, an NSValue containing a CGRect, and a UIColor
@property (strong,nonatomic) NSArray* boxes;

@end
