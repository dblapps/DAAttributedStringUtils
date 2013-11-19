//
//  DAAttributedLabel.h
//  PrairieSchooner
//
//  Created by David Levi on 1/10/13.
//  Copyright (c) 2013 Double Apps Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class DAAttributedLabel;

@protocol DAAttributedLabelDelegate
- (void) label:(DAAttributedLabel*)label didSelectLink:(NSInteger)linkNum;
@end

@interface DAAttributedLabel : UIView

// font and textColor are only used if text is an NSString
@property (strong,nonatomic) UIFont* font;
@property (strong,nonatomic) UIColor* textColor;

// text can be an NSString or NSAttributedString
@property (strong,nonatomic) id text;

// delegate is used for NSAttributedString instances containing clickable fields
#if __has_feature(objc_arc_weak)
@property (weak,nonatomic) id<DAAttributedLabelDelegate> delegate;
#else
@property (unsafe_unretained,nonatomic) id<DAAttributedLabelDelegate> delegate;
#endif

// This is deprecated, just set the text property directly
- (void) setText:(id)text withLinkRanges:(NSArray*)withLinkRanges;

// Forces the object to change its height to fit the entire string contained in the text property
- (void) setPreferredHeight;

// Returns height which will contain the entire string containted in the text property, using the current width
- (CGFloat) getPreferredHeight;

@end
