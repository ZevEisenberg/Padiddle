//
//  ColorPickerViewModel.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/17/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import Foundation
import CoreGraphics.CGBase

struct ColorPickerViewModel {
    var currentPage: Int = 0
    let colorsToPick = [
        ColorManager(
            colorModel: .HSV(
                h: .ThetaIncreasing,
                s: .Manual(1.0),
                v: .VelocityIn),
            title: NSLocalizedString("Classic", comment: "The original color scheme")),

        ColorManager(
            colorModel: .HSV(
                h: .Manual(30.0 / 360.0),
                s: .Manual(0.2),
                v: .ThetaIncreasingAndDecreasing),
            title: NSLocalizedString("Sepia", comment: "A color scheme named after the light brown color derived from cuttlefish ink")),

        ColorManager(
            colorModel: .HSV(
                h: .Manual(0.0),
                s: .Manual(1.0),
                v: .VelocityIn),
            title: NSLocalizedString("Black Widow", comment: "A color scheme with a red center like a black widow spider")),

        ColorManager(
            colorModel: .RGB(
                r: .VelocityOut,
                g: .Manual(0.0),
                b: .Manual(0.0)),
            title: NSLocalizedString("Autumn", comment: "A color scheme that looks like autumn leaves")),

        ColorManager(
            colorModel: .HSV(
                h: .Manual(30.0 / 360.0),
                s: .VelocityIn,
                v: .Manual(1.0)),
            title: NSLocalizedString("Tangerine", comment: "A color scheme that is bright, tagnerine yellow")),

        ColorManager(
            colorModel: .RGB(
                r: .ThetaIncreasingAndDecreasing,
                g: .ThetaIncreasing,
                b: .ThetaIncreasing),
            title: NSLocalizedString("3-D", comment: "A color scheme that looks like red-cyan 3-D glasses")),

        ColorManager(
            colorModel: .RGB(
                r: .ThetaIncreasingAndDecreasing,
                g: .VelocityIn,
                b: .ThetaIncreasing),
            title: NSLocalizedString("Watercolor", comment: "A color scheme with bright tones like watercolor paint")),

        ColorManager(
            colorModel: .RGB(
                r: .VelocityIn,
                g: .VelocityOut,
                b: .VelocityIn),
            title: NSLocalizedString("Monsters", comment: "A color scheme that looks like Mike and Sully from Monsters, Inc.")),

        ColorManager(
            colorModel: .HSV(
                h: .VelocityIn,
                s: .Manual(0.33),
                v: .ThetaIncreasingAndDecreasing),
            title: NSLocalizedString("Pastels", comment: "A color scheme with muted pastel hues")),

        ColorManager(
            colorModel: .HSV(
                h: .VelocityIn,
                s: .VelocityOut,
                v: .ThetaIncreasingAndDecreasing),
            title: NSLocalizedString("Merlin", comment: "A color scheme that looks like 1998’s Merlin TV mini-series")),

        ColorManager(
            colorModel: .HSV(
                h: .Manual(0.0),
                s: .Manual(0.0),
                v: .VelocityOut),
            title: NSLocalizedString("Regolith", comment: "A color scheme that looks like the surface of the moon")),

        ColorManager(
            colorModel: .HSV(
                h: .Manual(0.0),
                s: .Manual(0.0),
                v: .ThetaIncreasingAndDecreasing),
            title: NSLocalizedString("Film Noir", comment: "A color scheme that looks like black and white detective movies from the 1950s")),
    ]
}
