DAAttributedStringUtils
=======================

#### Author

David B. Levi (https://hithub.com/dblapps)


#### Overview

DAAttributedStringUtils is a set of simple utilities for working with the NSAttributedString class on iOS.  It consists of three classes:

DAFontSet - This is a general purpose class for working with fonts.  It is mainly used by the DAAttributedStringFormatter class, but can be used independently.  It provides mechanisms to translate a font to an italic version, to a non-italic version, or to a different weight (i.e., make a font more or less bold).

DAAttributedStringFormatter - This class takes an NSString instance containing text with embedded formatting codes, and translates this to an NSAttributedString instance.  The formatting codes look a little like printf-style formatting codes.

DAAttributedLabel - This is a simple UIView subclass that uses a CATextLayer to display an NSAttributedString.  It will handle wrapping the NSAttributedString over multiple lines, and provides a method to force an instance to adjust its frame height to accomodate its entire configured text.

An example xcode project is included that demonstrates some simple usage of all 3 classes. 

DAAttributeStringUtils is compatible with iOS5 and iOS6.


#### License

DAAttributedStringUtils is available under the MIT license. See the LICENSE file for more info.


#### How To Use

Copy the contents of the DAAttributedStringUtils directory to your xcode project.  Make sure the DAFontSet.plist file is included in your target's file membership.

Import the .h file(s) for the classes you want to use.

Add the CoreText and QuartzCore frameworks to your project.

DAFontSet:

DAFontSet is used to generate instances of UIFont, given either a font family name, or an existing UIFont instance.  Given a UIFont instance, you can generate a new instance relative to the existing instance.  So, for example, you could generate an italic version of a regular font, or a larger or smaller point size, or a bolder or lighter version.  The basic idea is that you provide either a family name or a UIFont instance, along with some details about the font you need, and DAFontSet will derive an appropriate UIFont instance.

These are the available font family names:

	Font Family Name			Available Weights
	----------------			-----------------
	Avenir					-2 .. 3
	TrebuchetMS				0 .. 1
	Arial					0 .. 1
	Cochin					0 .. 1
	Verdana					0 .. 1
	Courier					0 .. 1
	HoeflerText				0 .. 1
	Helvetica				-1 .. 1
	Optima					0 .. 2
	TimesNewRoman				0 .. 1
	Baskerville				0 .. 2
	AmericanTypewriter			-1 .. 1
	AmericanTypewriter-Condensed		-1 .. 1
	AvenirNext				-1 .. 4
	Georgia					0 .. 1
	HelveticaNeue				-2 .. 2
	GillSans				-1 .. 1
	Palatino				0 .. 1
	CourierNew				0 .. 1

DAFontSet divides the available fonts into regular and italic versions, and there are separate methods for each.

For bold fonts, DAFontSet uses a weight value.  A weight of 0 means a normal weight font.  Weight values larger than 0 refer to varying bold fonts (the larger the number, the more bold the font), and values smaller than 0 refer to lighter fonts.  Usually you will just use weight values of 0 or 1, for normal or bold.  But some fonts have additional lighter or bolder versions.

So, for example, you could create an italic bold version of HelveticaNeue with a point size of 24 like this:

	UIFont* font1 = [DAFontSet italicFontWithFamily:@"HelveticaNeue" size:24.0f weight:1];

You could then generate a lighter version of the font like this:

	UIFont* font2 = [DAFontSet changeWeightTo:0 forFont:font1];

or:

	UIFont* font3 = [DAFontSet changeWeightBy:-1 forFont:font1];

You could also get a regular version of the font like this:

	UIFont* font4 = [DAFontSet regularFontForFont:font1];

and then get the italic version of that:

	UIFont* font5 = [DAFontSet italicFontForFont:font4];

Of course, the available fonts have different weights available, as shown in the table above.  Also, not all fonts weights are available in italic versions.  DAFontSet will try to adjust to the closest available weight if the desired weight is not available, and will choose the regular version if an italic version is not available.


DAAttributedStringFormatter:

DAAttributedStringFormatter translates NSString instances with embedded formatting codes into NSAttributedString instances.  First create an instance of DAAttributedStringFormatter, and configure it with the colors and font families you want to use.  Then pass instances of NSString to the formatter's formatString: method.  For example, to create a string containing some red and blue text using Courier and Arial fonts:

	DAAttributedStringFormatter* formatter = [[DAAttributedStringFormatter alloc] init];
	formatter.fontFamilies = @[ @"Courier", @"Arial" ];
	formatter.colors = @[ [UIColor redColor], [UIColor blueColor] ];
	NSAttributedString* attrStr = [formatter formatString:@"%0C%0FRed Courier Text %1C%1FBlue Arial Text %0CRed Arial Text"];

Formatters also have a default point size, font, and color.  These are used in the absence of explicit formatting codes.  The initial default font is 17-point Helvetica, and the initial default color is black.  You can change these with the defaultPointSize, defaultFontFamily, and defaultColor properties:

	formatter.defaultPointSize = 24.0f;
	formatter.defaultFontFamily = @"Georgia";
	formatter.defaultColor = [UIColor orangeColor];

Formatting codes are prefixed by a '%' character.  To put a '%' character as text in the string, use '%%'.  Otherwise, the general form for a formatter is %xY, where x is an optional integer number, and Y is a character specifying the attribute to modify.  Specific codes are as follows:

	Code	Meaning
	----	----------------------------------------------
	%f	Set font family to default.  This changes the font family only.
	%xF	Set font family to font family number x from the fontFamilies property array.  Numbering starts at 0.
	%c	Set text color to the default.
	%xC	Set text color to a color from the colors property array.  Numbering starts at 1.
	%u	Turn underlining off.
	%xU	Set underlining.  If x==0, underlining is turned off.  If x==1, single underlining is turned on.  If x==2, double underlining is turned on.
	%xW	Set current font weight (see discussion of DAFontSet above).
	%B	Set the font to bold.  This sets the font weight to 1.
	%b	Turn off bold.  This sets the font weight to 0.
	%I	Turn on italics.
	%i	Turn off italics.
	%N	Reset the font family, style, underlining, and size to defaults.
	%xS	Set the font size.
	%s	Reset to the default font size.


DAAttributedLabel:

DAAttributedLabel is a simple UIView subclass for displaying an NSAttributedString in a CATextLayer.  It can also display a plain NSString.  To use it create an instance, set the text property to an instance of an NSString or NSAttributedString, and add it to a subview.  By default, the CATextLayer will wrap text.  After setting the label's frame, you can call the setPreferredHeight method.  This will adjust the height of the label to accomodate the entire text string.  The example project shows how this is done.
