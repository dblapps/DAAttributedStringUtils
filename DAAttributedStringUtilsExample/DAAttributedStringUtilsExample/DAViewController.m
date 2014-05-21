//
//  DAViewController.m
//  DAAttributedStringUtilsExample
//
//  Created by David Levi on 1/23/13.
//  Copyright (c) 2013 Double Apps Inc. All rights reserved.
//

#import "DAViewController.h"
#import "DAFontSet.h"
#import "DAAttributedStringFormatter.h"
#import "DAAttributedLabel.h"

@interface DAViewController () <DAAttributedLabelDelegate>
{
	UILabel* msg;
	NSTimer* msgTimer;
}
@end

@implementation DAViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	DAAttributedStringFormatter* formatter = [[DAAttributedStringFormatter alloc] init];
	formatter.defaultFontFamily = @"Helvetica";
	formatter.defaultColor = [UIColor blueColor];
	formatter.fontFamilies = @[ @"Courier", @"Arial", @"Georgia" ];
	formatter.defaultPointSize = 17.0f;
	formatter.colors = @[ [UIColor blackColor], [UIColor redColor], [UIColor greenColor] ];
	
	DAAttributedLabel* label1 = [[DAAttributedLabel alloc] initWithFrame:CGRectMake(30.0f, 30.0f, 260.0f, 24.0f)];
	label1.backgroundColor = [UIColor colorWithRed:0.9f green:0.9f blue:1.0f alpha:1.0f];
	label1.text = (id)[formatter formatString:@"Normal %BBold%b %IItalic%i %B%IBold-Italic%i%b"];
	label1.text = (id)@"This is plain text";
	[self.view addSubview:label1];
	
	DAAttributedLabel* label2 = [[DAAttributedLabel alloc] initWithFrame:CGRectMake(30.0f, 60.0f, 260.0f, 24.0f)];
	label2.backgroundColor = [UIColor colorWithRed:0.9f green:0.9f blue:1.0f alpha:1.0f];
	label2.text = (id)[formatter formatString:@"This is some long text with colors %0CBLACK%c and %1CRED%c and %2CGREEN%c, background colors of %1DRED%d and %2DGREEN%d, plus fonts %0FCOURIER%f and %1FArial%f and %2FGeorgia%f, plus %40S%2DBIGGER%d%s and %8SSMALLER%s text."];
	[label2 setPreferredHeight];
	[self.view addSubview:label2];

	UIScrollView* sv = [[UIScrollView alloc] initWithFrame:CGRectMake(30.0f, CGRectGetMaxY(label2.frame) + 6.0f, 260.0f, 200.0f)];
	DAAttributedLabel* label3 = [[DAAttributedLabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 260.0f, 24.0f)];
	label3.backgroundColor = [UIColor colorWithRed:0.9f green:0.9f blue:1.0f alpha:1.0f];
	NSAttributedString* attrStr = [formatter formatString:@"This is %B%LClickable%l%b text.  You %B%1U%Lcan also%l%u%b click on %B%LThis longer text.%l%b  "
								   @"This is %B%LClickable%l%b text.  "
								   @"This is %B%LClickable%l%b text.  "
								   @"This is %B%LClickable%l%b text.  "
								   @"This is %B%LClickable%l%b text.  "
								   @"This is %B%LClickable%l%b text.  "
								   @"This is %B%LClickable%l%b text.  "
								   @"This is %B%LClickable%l%b text.  "
								   @"This is %B%LClickable%l%b text.  "
								   @"This is %B%LClickable%l%b text.  "
								   @"This is %B%LClickable%l%b text.  "
								   @"This is %B%LClickable%l%b text.  "
								   @"This is %B%LClickable%l%b text.  "
								   @"This is %B%LClickable%l%b text.  "];
	label3.text = attrStr;
	[label3 setPreferredHeight];
	label3.delegate = self;
	[self.view addSubview:sv];
	[sv addSubview:label3];
	sv.contentSize = CGSizeMake(1.0f,label3.frame.size.height);
	msg = [[UILabel alloc] initWithFrame:CGRectMake(30.0f, sv.frame.origin.y + sv.frame.size.height + 10.0f, 260.0f, 24.0f)];
	msg.backgroundColor = [UIColor clearColor];
	msg.text = @"CLICKED ON LINK: ";
	[self.view addSubview:msg];
}

- (void) msgTimerExpired:(NSTimer*)timer
{
	msgTimer = nil;
	msg.text = @"CLICKED ON LINK: ";
}

- (void) label:(DAAttributedLabel *)label didSelectLink:(NSInteger)linkNum
{
	[msgTimer invalidate];
	msgTimer = nil;
	msg.text = [NSString stringWithFormat:@"CLICKED ON LINK: %ld", (long)linkNum];
	msgTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(msgTimerExpired:) userInfo:nil repeats:NO];
}

@end
