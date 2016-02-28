//
//  Math.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 10/25/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import CoreGraphics.CGBase

let π = CGFloat(M_PI)
let twoPi = 2.0 * π
let bytesPerPixel: size_t = 4
let bitsPerComponent: size_t = 8

extension CGFloat {
    func closeEnough(to: CGFloat) -> Bool {
        let epsilon = CGFloat(0.0001)
        let closeEnough = fabs(self - to) < epsilon
        return closeEnough
    }

    var reasonableValue: CGFloat {
        get {
            if self.closeEnough(0) {
                return 0
            } else {
                return self
            }
        }
    }

    var degrees: CGFloat {
        return self * 180 / π
    }
}
