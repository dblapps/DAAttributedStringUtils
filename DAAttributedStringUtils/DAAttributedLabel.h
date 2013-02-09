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
{
	UIFont* _font;
	UIColor* _textColor;
}

@property (strong,nonatomic) UIFont* font;
@property (strong,nonatomic) UIColor* textColor;
@property (strong,nonatomic) id text;
@property (readonly) CATextLayer* textLayer;
#if __has_feature(objc_arc_weak)
@property (weak,nonatomic) id<DAAttributedLabelDelegate> delegate;
#else
@property (unsafe_unretained,nonatomic) id<DAAttributedLabelDelegate> delegate;
#endif

- (void) setText:(id)text withLinkRanges:(NSArray*)withLinkRanges;
- (void) setPreferredHeight;

@end
