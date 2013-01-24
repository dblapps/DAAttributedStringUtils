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

@interface DAViewController ()

@end

@implementation DAViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

	DAAttributedStringFormatter* formatter = [[DAAttributedStringFormatter alloc] init];
	formatter.defaultFontFamily = @"Helvetica";
	formatter.defaultColor = [UIColor blueColor];
	formatter.fontFamilies = @[ @"Courier", @"Arial", @"Georgia" ];
	formatter.colors = @[ [UIColor blackColor], [UIColor redColor], [UIColor greenColor] ];
	
	DAAttributedLabel* label1 = [[DAAttributedLabel alloc] initWithFrame:CGRectMake(30.0f, 30.0f, 260.0f, 24.0f)];
	label1.backgroundColor = [UIColor colorWithRed:0.9f green:0.9f blue:1.0f alpha:1.0f];
	label1.text = (id)[formatter formatString:@"Normal %BBold%b %IItalic%i %B%IBold-Italic%i%b"];
	[self.view addSubview:label1];
	
	DAAttributedLabel* label2 = [[DAAttributedLabel alloc] initWithFrame:CGRectMake(30.0f, 80.0f, 260.0f, 24.0f)];
	label2.backgroundColor = [UIColor colorWithRed:0.9f green:0.9f blue:1.0f alpha:1.0f];
	label2.text = (id)[formatter formatString:@"This is some long text with colors %0CBLACK%c and %1CRED%c and %2CGREEN%c, plus fonts %0FCOURIER%f and %1FArial%f and %2FGeorgia%f, plus %40SBIGGER%s and %8SSMALLER%s text."];
	[label2 setPreferredHeight];
	[self.view addSubview:label2];
}

@end
