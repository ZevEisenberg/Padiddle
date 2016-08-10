//
//  ColorManager.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/15/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit.UIColor

enum ColorMode {
    case thetaIncreasing
    case thetaIncreasingAndDecreasing
    case velocityOut
    case velocityIn
    case manual(CGFloat)
}

enum ColorModel {
    case hsv(h: ColorMode, s: ColorMode, v: ColorMode)
    case rgb(r: ColorMode, g: ColorMode, b: ColorMode)
}

struct ColorManager {
    var radius: CGFloat = 0
    var theta: CGFloat = 0 {
        didSet {
            theta = theta.truncatingRemainder(dividingBy: twoPi)
        }
    }

    var maxRadius: CGFloat = 0

    let colorModel: ColorModel

    var title: String

    var currentColor: UIColor {
        return self.dynamicType.color(colorModel: colorModel, radius: radius, maxRadius: maxRadius, theta: theta)
    }

    init(colorModel: ColorModel, title: String) {
        self.colorModel = colorModel
        self.title = title
    }

    private static func color(colorModel: ColorModel, radius: CGFloat, maxRadius: CGFloat, theta: CGFloat) -> UIColor {
        let color: UIColor
        switch colorModel {
        case let .hsv(hMode, sMode, vMode):
            let h = channelValue(radius, maxRadius: maxRadius, theta: theta, colorMode: hMode)
            let s = channelValue(radius, maxRadius: maxRadius, theta: theta, colorMode: sMode)
            let v = channelValue(radius, maxRadius: maxRadius, theta: theta, colorMode: vMode)
            color = UIColor(hue: h, saturation: s, brightness: v, alpha: 1)
        case let .rgb(rMode, gMode, bMode):
            let r = channelValue(radius, maxRadius: maxRadius, theta: theta, colorMode: rMode)
            let g = channelValue(radius, maxRadius: maxRadius, theta: theta, colorMode: gMode)
            let b = channelValue(radius, maxRadius: maxRadius, theta: theta, colorMode: bMode)
            color = UIColor(red: r, green: g, blue: b, alpha: 1)
        }

        return color
    }

    private static func channelValue(_ radius: CGFloat, maxRadius: CGFloat, theta: CGFloat, colorMode: ColorMode) -> CGFloat {
        let channelValue: CGFloat
        switch colorMode {
        case .thetaIncreasing:
            channelValue = theta / twoPi

        case .thetaIncreasingAndDecreasing:
            var value: CGFloat
            if theta > .pi {
                value = twoPi - theta
            } else {
                value = theta
            }
            channelValue = value / .pi

        case .velocityOut:
            assert(maxRadius > 0)
            channelValue = radius / maxRadius

        case .velocityIn:
            assert(maxRadius > 0)
            channelValue = 1 - (radius / maxRadius)

        case let .manual(value):
            channelValue = value
        }

        return channelValue
    }
}
