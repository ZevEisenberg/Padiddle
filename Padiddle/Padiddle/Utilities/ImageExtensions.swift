//
//  ImageExtensions.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 10/7/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit

extension UIImage {
    class func ellipseImage(color: UIColor, size: CGSize, borderWidth: CGFloat, borderColor: UIColor) -> UIImage {
        // Build a rect of appropriate size at origin (1,1)
        let fullRect = CGRect(origin: CGPoint.zero, size: size)
        let insetRect = fullRect.insetBy(dx: borderWidth / 2.0, dy: borderWidth / 2.0)

        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let currentContext = UIGraphicsGetCurrentContext()

        // Add ellipse for masking
        currentContext?.addEllipse(in: insetRect)

        // Save the graphics state so we can undo the clip to draw the stroke
        currentContext?.saveGState()

        // Clip the context by the current path to get rid of
        // the part of the stroke that drew outside the line
        currentContext?.clip()

        // Set the fill color
        currentContext?.setFillColor(color.cgColor)

        // Fill the color
        currentContext?.fill(fullRect)

        // Undo the clip so the stroke draws inside and out
        currentContext?.restoreGState()

        // Set up the stroke
        currentContext?.setStrokeColor(borderColor.cgColor)
        currentContext?.setLineWidth(borderWidth)

        // Stroke the color
        currentContext?.strokeEllipse(in: insetRect)

        //Snap the picture and close the context
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image!
    }

    func imageRotatedByRadians(_ radians: CGFloat) -> UIImage {
        // Don't optimize out the radians == 0 case by just returning self.
        // It results in an image that is flipped vertically.
        // I likely have a double rotation somewhere.

        var rotatedSize: CGSize
        if radians == .pi || radians == 0 {
            rotatedSize = self.size
        } else {
            rotatedSize = CGSize(width: size.height, height: size.width)
        }

        // Scale the size so it represents pixels instead of points
        rotatedSize.width *= scale
        rotatedSize.height *= scale

        let context = createContext()

        // Move the origin to the middle of the image so we will rotate and scale around the center.
        context?.translateBy(x: size.width * scale / 2, y: size.height * scale / 2)

        // Rotate the image context
        context?.rotate(by: radians)

        // Now, draw the rotated/scaled image into the context
        let imageRect = CGRect(
            x: -rotatedSize.width / 2,
            y: -rotatedSize.height / 2,
            width: rotatedSize.width,
            height: rotatedSize.height)

        context?.scaleBy(x: 1.0, y: -1.0)
        context?.draw(self.cgImage!, in: imageRect)

        let newImage = context?.makeImage()!

        let retImage = UIImage(cgImage: newImage!, scale: scale, orientation: .up)

        return retImage
    }

    var imageFlippedHorizontally: UIImage {
        return imageScaledBy(CGVector(dx: -1, dy: 1))
    }

    var imageFlippedVertically: UIImage {
        return imageScaledBy(CGVector(dx: 1, dy: -1))
    }

    class func recordButtonImage() -> UIImage {
        let backgroundImage = UIImage(asset: .recordButtonBack)
        let foregroundImage = UIImage(asset: .recordButtonFront)

        let contextSize = CGSize.max((foregroundImage?.size)!, (backgroundImage?.size)!)
        UIGraphicsBeginImageContextWithOptions(contextSize, false, 0)

        let backgroundImageBounds = CGRect(origin: CGPoint.zero, size: (backgroundImage?.size)!)
        let foregroundImageBounds = CGRect(origin: CGPoint.zero, size: (backgroundImage?.size)!)

        let contextRect = CGRect(origin: CGPoint.zero, size: contextSize)

        let backgroundImageFrame = contextRect.centerSmallerRect(backgroundImageBounds)
        let foregroundImageFrame = contextRect.centerSmallerRect(foregroundImageBounds)

        backgroundImage?.draw(in: backgroundImageFrame)
        foregroundImage?.draw(in: foregroundImageFrame)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }

    private func imageScaledBy(_ scaleVector: CGVector) -> UIImage {

        let bitmapBytesPerRow: size_t = size_t(size.width) * bytesPerPixel * size_t(scale)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let bitmap = CGContext(data: nil,
            width: Int(size.width * scale),
            height: Int(size.height * scale),
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bitmapBytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)

        // Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap?.translateBy(x: size.width * scale / 2, y: size.height * scale / 2)

        bitmap?.scaleBy(x: scaleVector.dx, y: scaleVector.dy)

        // Now, draw the rotated/scaled image into the context
        let drawRect = CGRect(
            x: -size.width * scale / 2,
            y: -size.height * scale / 2,
            width: size.width * scale,
            height: size.height * scale)
        bitmap?.draw(self.cgImage!, in: drawRect)

        let newImage = bitmap?.makeImage()!

        let retImage = UIImage(cgImage: newImage!, scale: scale, orientation: .up)

        return retImage
    }

    private func createContext() -> CGContext? {
        // Create the bitmap context
        let bitmapBytesPerRow: size_t = size_t(size.width) * bytesPerPixel * size_t(scale)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let context = CGContext(data: nil,
            width: Int(size.width * scale),
            height: Int(size.height * scale),
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bitmapBytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)

        return context
    }
}
