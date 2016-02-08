//
//  ImageMaker.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/18/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit

struct SpiralModel {
    let colorManager: ColorManager
    let size: CGSize
    let startRadius: CGFloat
    let spacePerLoop: CGFloat
    let thetaRange: ClosedInterval<CGFloat>
    let thetaStep: CGFloat
    let lineWidth: CGFloat
}

struct SpiralImageMaker {
    static func image(spiralModel spiralModel: SpiralModel) -> UIImage {

        let size = spiralModel.size
        let startRadius = spiralModel.startRadius
        let spacePerLoop = spiralModel.spacePerLoop
        let thetaRange = spiralModel.thetaRange
        let thetaStep = spiralModel.thetaStep
        let lineWidth = spiralModel.lineWidth

        var mutableColorManager = spiralModel.colorManager

        mutableColorManager.maxRadius = size.width / 2

        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)

        // spiral parameters
        let center = CGPoint(x: (size.width / 2) - 1, y: (size.height / 2) + 2)
        let a = startRadius // start distance from center
        let b = spacePerLoop // space between each loop

        let path = UIBezierPath()
        path.lineWidth = lineWidth
        path.lineCapStyle = .Square
        path.lineJoinStyle = .Round

        var oldTheta = thetaRange.start
        var newTheta = thetaRange.start
        mutableColorManager.theta = thetaRange.start
        mutableColorManager.radius = a

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
        while oldTheta < (thetaRange.end - thetaStep) {
            path.removeAllPoints()
            path.moveToPoint(newPoint)

            oldTheta = newTheta
            newTheta += thetaStep
            mutableColorManager.theta = newTheta

            oldR = newR
            newR = a + b * newTheta
            mutableColorManager.radius = newR

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
            } else {
                oldSlope = newSlope
            }
            newSlope = (b * sin(newTheta) + aPlusBTheta * cos(newTheta)) / (b * cos(newTheta) - aPlusBTheta * sin(newTheta))

            var controlPoint = CGPoint.zero

            let oldIntercept = -(oldSlope * oldR * cos(oldTheta) - oldR * sin(oldTheta))
            let newIntercept = -(newSlope * newR * cos(newTheta) - newR * sin(newTheta))

            if let intersection = CGPoint.lineIntersection(m1: oldSlope, b1: oldIntercept, m2: newSlope, b2: newIntercept) {
                controlPoint = intersection
            } else {
                fatalError("lines are parallel")
            }

            controlPoint.x += center.x
            controlPoint.y += center.y

            path.addQuadCurveToPoint(newPoint, controlPoint: controlPoint)

            let color = mutableColorManager.currentColor
            color.setStroke()

            if !(oldTheta < (thetaRange.end - thetaStep)) {
                path.lineCapStyle = .Round
            }
            path.stroke()
        }

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
}
