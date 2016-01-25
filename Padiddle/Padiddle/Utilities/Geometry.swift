//
//  Geometry.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 10/16/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import CoreGraphics.CGGeometry
import UIKit.UIScreen

struct Geometry {
    static func distanceBetween(let p1: CGPoint, let p2: CGPoint) -> CGFloat {
        if CGPointEqualToPoint(p1, p2) {
            return 0
        } else {
            return sqrt(pow((p1.x - p2.x), 2.0) + pow((p1.y - p2.y), 2.0))
        }
    }

    static func lineIntersection(let m1: CGFloat, let b1: CGFloat, let m2: CGFloat, let b2: CGFloat) -> CGPoint? {
        if m1 == m2 {
            // lines are parallel
            return nil
        }

        let returnX = (b2 - b1) / (m1 - m2)

        let returnY = m1 * returnX + b1

        return CGPoint(x: returnX, y: returnY)
    }
}

extension CGSize {
    static func max(size1: CGSize, _ size2: CGSize) -> CGSize {
        let maxWidth = Swift.max(size1.width, size2.width)
        let maxHeight = Swift.max(size1.height, size2.height)
        return CGSize(width: maxWidth, height: maxHeight)
    }
}

extension CGRect {
    func centerSmallerRect(smallerRect: CGRect) -> CGRect {
        assert(smallerRect.width <= self.width)
        assert(smallerRect.height <= self.height)

        let newRect = smallerRect.offsetBy(
            dx: (self.width - smallerRect.width) / 2,
            dy: (self.height - smallerRect.height) / 2
        )

        return newRect
    }
}

extension CGPoint {
    var screenPixelsIntegral: CGPoint {
        let screenScale = UIScreen.mainScreen().scale
        var newX = x
        var newY = y

        // integralize to screen pixels
        newX *= screenScale
        newY *= screenScale

        newX = round(newX)
        newY = round(newY)

        newX /= screenScale
        newY /= screenScale

        return CGPoint(x: newX, y: newY)
    }
}

extension UIInterfaceOrientation {
    var imageRotation: (orientation: UIImageOrientation, rotation: CGFloat) {
        let rotation: CGFloat
        let imageOrientaion: UIImageOrientation

        switch self {
        case .LandscapeLeft:
            rotation = -π / 2.0
            imageOrientaion = .Right
        case .LandscapeRight:
            rotation = π / 2.0
            imageOrientaion = .Left
        case .PortraitUpsideDown:
            rotation = π
            imageOrientaion = .Down
        case .Portrait, .Unknown:
            rotation = 0
            imageOrientaion = .Up
        }

        return (imageOrientaion, rotation)
    }
}
