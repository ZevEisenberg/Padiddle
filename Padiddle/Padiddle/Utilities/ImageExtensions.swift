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
        let fullRect = CGRect(origin: CGPoint.zero, size: size)
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

    func imageRotatedByRadians(radians: CGFloat) -> UIImage {
        // Don't optimize out the radians == 0 case by just returning self.
        // It results in an image that is flipped vertically.
        // I likely have a double rotation somewhere.

        var rotatedSize: CGSize
        if radians == π || radians == 0 {
            rotatedSize = self.size
        } else {
            rotatedSize = CGSize(width: size.height, height: size.width)
        }

        // Scale the size so it represents pixels instead of points
        rotatedSize.width *= scale
        rotatedSize.height *= scale

        // Create the bitmap context
        let bytesPerPixel: size_t = 4
        let bitsPerComponent: size_t = 8
        let bitmapBytesPerRow: size_t = size_t(size.width) * bytesPerPixel * size_t(scale)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let context = CGBitmapContextCreate(nil,
            Int(size.width * scale),
            Int(size.height * scale),
            bitsPerComponent,
            bitmapBytesPerRow,
            colorSpace,
            CGImageAlphaInfo.NoneSkipLast.rawValue)

        // Move the origin to the middle of the image so we will rotate and scale around the center.
        CGContextTranslateCTM(context, size.width * scale / 2, size.height * scale / 2)

        // Rotate the image context
        CGContextRotateCTM(context, radians)

        // Now, draw the rotated/scaled image into the context
        let imageRect = CGRect(
            x: -rotatedSize.width / 2,
            y: -rotatedSize.height / 2,
            width: rotatedSize.width,
            height: rotatedSize.height)

        CGContextScaleCTM(context, 1.0, -1.0)
        CGContextDrawImage(
            context,
            imageRect,
            self.CGImage
        )

        let newImage = CGBitmapContextCreateImage(context)!

        let retImage = UIImage(CGImage: newImage, scale: scale, orientation: .Up)

        return retImage
    }

    var imageFlippedHorizontally: UIImage {
        return imageScaledBy(CGVector(dx: -1, dy: 1))
    }

    var imageFlippedVertically: UIImage {
        return imageScaledBy(CGVector(dx: 1, dy: -1))
    }

    private func imageScaledBy(scaleVector: CGVector) -> UIImage {

        let bytesPerPixel: size_t = 4
        let bitsPerComponent: size_t = 8
        let bitmapBytesPerRow: size_t = size_t(size.width) * bytesPerPixel * size_t(scale)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let bitmap = CGBitmapContextCreate(nil,
            Int(size.width * scale),
            Int(size.height * scale),
            bitsPerComponent,
            bitmapBytesPerRow,
            colorSpace,
            CGImageAlphaInfo.NoneSkipLast.rawValue)

        // Move the origin to the middle of the image so we will rotate and scale around the center.
        CGContextTranslateCTM(bitmap, size.width * scale / 2, size.height * scale / 2)

        CGContextScaleCTM(bitmap, scaleVector.dx, scaleVector.dy)

        // Now, draw the rotated/scaled image into the context
        let drawRect = CGRect(
            x: -size.width * scale / 2,
            y: -size.height * scale / 2,
            width: size.width * scale,
            height: size.height * scale)
        CGContextDrawImage(bitmap, drawRect, self.CGImage)

        let newImage = CGBitmapContextCreateImage(bitmap)!

        let retImage = UIImage(CGImage: newImage, scale: scale, orientation: .Up)

        return retImage
    }
}
