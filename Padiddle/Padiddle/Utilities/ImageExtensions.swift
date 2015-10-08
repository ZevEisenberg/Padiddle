//
//  ImageExtensions.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 10/7/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit

extension UIImage {
    class func ellipseImageWithColor(color color: UIColor, size: CGSize, borderWidth: CGFloat, borderColor: UIColor) -> UIImage {
        // Build a rect of appropriate size at origin (1,1)
        let fullRect = CGRectMake(0, 0, size.width, size.height)
        let insetRect = CGRectInset(fullRect, borderWidth / 2.0, borderWidth / 2.0)

        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let currentContext = UIGraphicsGetCurrentContext()

        // Add ellipse for masking
        CGContextAddEllipseInRect(currentContext, insetRect)

        // Save the graphics state so we can undo the clip to draw the stroke
        CGContextSaveGState(currentContext)

        // Clip the context by the current path to get rid of
        // the part of the stroke that drew outside the line
        CGContextClip(currentContext)

        // Set the fill color
        CGContextSetFillColorWithColor(currentContext, color.CGColor)

        // Fill the color
        CGContextFillRect(currentContext, fullRect)

        // Undo the clip so the stroke draws inside and out
        CGContextRestoreGState(currentContext)

        // Set up the stroke
        CGContextSetStrokeColorWithColor(currentContext, borderColor.CGColor)
        CGContextSetLineWidth(currentContext, borderWidth)

        // Stroke the color
        CGContextStrokeEllipseInRect(currentContext, insetRect)

        //Snap the picture and close the context
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
}
