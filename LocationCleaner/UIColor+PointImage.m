//
//  UIColor+PointImage.m
//  LocationCleaner
//
//  Created by Jonny on 10/26/17.
//  Copyright © 2017 Jonny. All rights reserved.
//

#import "UIColor+PointImage.h"

@implementation UIColor (PointImage)

/**
 Make a 1ptx1pt image that fill with the color.
 
 @return The color image.
 */
- (UIImage *)kjy_makePointImage;
{
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContextWithOptions(rect.size, YES, UIScreen.mainScreen.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [self CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
