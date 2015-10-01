//
//  ColorPickerViewModel.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/17/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit
import CoreGraphics.CGBase

class ColorPickerViewModel {
    var currentPage: Int = 0
    var selectedIndex: Int {
        get {
            return Defaults.colorPickerSelection
        }
        set(newValue) {
            Defaults.colorPickerSelection = newValue
        }
    }
    var selectedColorManager: ColorManager {
        return colorsToPick[selectedIndex]
    }

    func indexPathsForItemsOnPageWithIndexPath(indexPath: NSIndexPath) -> [NSIndexPath] {
        //--------------------------------------------------
        // The layout doesn’t exist yet, so we can’t query
        // its properties, so we use the same information
        // it uses to derive its items per page.
        //--------------------------------------------------
        let itemsPerPage = colsPortrait * rowsPortrait

        let page = indexPath.item / itemsPerPage;

        var indexPaths = [NSIndexPath]()

        for item in 0..<itemsPerPage {
            indexPaths.append(NSIndexPath(forItem: (itemsPerPage * page) + item, inSection: 0))
        }
        return indexPaths;
    }

    func imageForColorManager(colorManager: ColorManager) -> UIImage {
        let image = ImageMaker.image(colorManager,
            size: CGSize(width: 86, height: 86),
            startRadius: 0,
            spacePerLoop: 1.5,
            startTheta: 0,
            endTheta: 2.0 * CGFloat(M_PI) * 4.0,
            thetaStep: CGFloat(M_PI) / 32.0,
            lineWidth: 4.9)
        return image
    }
}

extension ColorPickerViewModel {
    var colorsToPick: [ColorManager] {
        return [ColorManager(
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
}
