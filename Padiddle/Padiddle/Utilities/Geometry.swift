//
//  Geometry.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 10/16/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import CoreGraphics.CGGeometry

struct Geometry {
    static func distanceBetween(let p1: CGPoint, let p2: CGPoint) -> CGFloat {
        if CGPointEqualToPoint(p1, p2) {
            return 0
        }
        else {
            return sqrt(pow((p1.x - p2.x), 2.0) + pow((p1.y - p2.y), 2.0));
        }
    }

    static func lineIntersection(let m1: CGFloat, let b1: CGFloat, let m2: CGFloat, let b2: CGFloat) -> CGPoint? {
        if m1 == m2 {
            // lines are parallel
            return nil;
        }

        let returnX = (b2 - b1) / (m1 - m2)

        let returnY = m1 * returnX + b1
        
        return CGPoint(x: returnX, y: returnY)
    }
}
