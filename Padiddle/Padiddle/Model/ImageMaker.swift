//
//  ImageMaker.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/18/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit

struct ImageMaker {
    static func image(
        var colorManager: ColorManager,
        size: CGSize,
        startRadius: CGFloat,
        spacePerLoop: CGFloat,
        startTheta: CGFloat,
        endTheta: CGFloat,
        thetaStep: CGFloat,
        lineWidth: CGFloat) -> UIImage {

            colorManager.maxRadius = size.width / 2

            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)

            // spiral parameters
            let center = CGPoint(x: (size.width / 2) - 1, y: (size.height / 2) + 2)
            let a = startRadius // start distance from center
            let b = spacePerLoop // space between each loop

            let path = UIBezierPath()
            path.lineWidth = lineWidth
            path.lineCapStyle = .Square
            path.lineJoinStyle = .Round

            var oldTheta = startTheta
            var newTheta = startTheta
            colorManager.theta = startTheta
            colorManager.radius = a

            var oldR = a + (b * oldTheta)
            var newR = a + (b * newTheta)

            var oldPoint = CGPoint.zero
            var newPoint = CGPoint.zero

            var oldSlope = CGFloat.max
            var newSlope = CGFloat.min

            // move to the initial point outside the loop, because we do it
            // only the first time
            newPoint.x = center.x + (oldR * cos(oldTheta))
            newPoint.y = center.y + (oldR * sin(oldTheta))

            var firstSlope = true
            while oldTheta < (endTheta - thetaStep) {
                path.removeAllPoints()
                path.moveToPoint(newPoint)

                oldTheta = newTheta
                newTheta += thetaStep
                colorManager.theta = newTheta

                oldR = newR
                newR = a + b * newTheta
                colorManager.radius = newR

                oldPoint.x = newPoint.x
                oldPoint.y = newPoint.y
                newPoint.x = center.x + (newR * cos(newTheta))
                newPoint.y = center.y + (newR * sin(newTheta))

                // slope calculation
                // (b * sinΘ + (a + bΘ) * cosΘ) / (b * cosΘ - (a + bΘ) * sinΘ)
                let aPlusBTheta = a + (b * newTheta)
                if firstSlope {
                    oldSlope = (b * sin(oldTheta) + aPlusBTheta * cos(oldTheta)) / (b * cos(oldTheta) - aPlusBTheta * sin(oldTheta))
                    firstSlope = false
                }
                else {
                    oldSlope = newSlope
                }
                newSlope = (b * sin(newTheta) + aPlusBTheta * cos(newTheta)) / (b * cos(newTheta) - aPlusBTheta * sin(newTheta))

                var controlPoint = CGPoint.zero

                let oldIntercept = -(oldSlope * oldR * cos(oldTheta) - oldR * sin(oldTheta))
                let newIntercept = -(newSlope * newR * cos(newTheta) - newR * sin(newTheta))

                if let intersection = Geometry.lineIntersection(oldSlope, b1: oldIntercept, m2: newSlope, b2: newIntercept) {
                    controlPoint = intersection
                }
                else {
                    fatalError("lines are parallel")
                }

                controlPoint.x += center.x
                controlPoint.y += center.y

                path.addQuadCurveToPoint(newPoint, controlPoint: controlPoint)

                let color = colorManager.currentColor
                color.setStroke()

                if !(oldTheta < (endTheta - thetaStep)) {
                    path.lineCapStyle = .Round
                }
                path.stroke()
            }

            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return image
    }
}
