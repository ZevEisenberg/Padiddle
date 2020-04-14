//
//  Math.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 10/25/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import CoreGraphics.CGBase

let twoPi = CGFloat(2.0 * .pi)
let bytesPerPixel: size_t = 4
let bitsPerComponent: size_t = 8

extension CGFloat {

    func closeEnough(to: CGFloat) -> Bool {
        let epsilon = CGFloat(0.0001)
        let closeEnough = abs(self - to) < epsilon
        return closeEnough
    }

    var reasonableValue: CGFloat {
        self.closeEnough(to: 0) ? 0 : self
    }

}
