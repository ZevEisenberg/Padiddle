//
//  ColorPickerViewModel.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/17/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit
import CoreGraphics.CGBase

protocol ColorPickerViewModelDelegate:
class {
    func colorManagerPicked(colorManager: ColorManager)
}

class ColorPickerViewModel {
    weak var delegate: ColorPickerViewModelDelegate?

    init(delegate: ColorPickerViewModelDelegate) {
        self.delegate = delegate
        delegate.colorManagerPicked(selectedColorManager)
    }

    var currentPage: Int = 0
    var selectedIndex: Int {
        get {
            return Defaults.colorPickerSelection
        }
        set(newValue) {
            Defaults.colorPickerSelection = newValue
            delegate?.colorManagerPicked(selectedColorManager)
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

        let page = indexPath.item / itemsPerPage

        var indexPaths = [NSIndexPath]()

        for item in 0..<itemsPerPage {
            indexPaths.append(NSIndexPath(forItem: (itemsPerPage * page) + item, inSection: 0))
        }
        return indexPaths
    }

    func imageForColorManager(colorManager: ColorManager) -> UIImage {
        let model = SpiralModel(
            colorManager: colorManager,
            size: CGSize(width: 86, height: 86),
            startRadius: 0,
            spacePerLoop: 1.5,
            thetaRange: 0...(2.0 * π * 4.0),
            thetaStep: π / 32.0,
            lineWidth: 4.9)

        let image = SpiralImageMaker.image(spiralModel: model)
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
            title: L10n.ColorsClassic.string),

            ColorManager(
                colorModel: .HSV(
                    h: .Manual(30.0 / 360.0),
                    s: .Manual(0.2),
                    v: .ThetaIncreasingAndDecreasing),
                title: L10n.ColorsSepia.string),

            ColorManager(
                colorModel: .HSV(
                    h: .Manual(0.0),
                    s: .Manual(1.0),
                    v: .VelocityIn),
                title: L10n.ColorsBlackWidow.string),

            ColorManager(
                colorModel: .RGB(
                    r: .VelocityOut,
                    g: .Manual(0.45),
                    b: .Manual(0.0)),
                title: L10n.ColorsAutumn.string),

            ColorManager(
                colorModel: .HSV(
                    h: .Manual(30.0 / 360.0),
                    s: .VelocityIn,
                    v: .Manual(1.0)),
                title: L10n.ColorsTangerine.string),

            ColorManager(
                colorModel: .RGB(
                    r: .ThetaIncreasingAndDecreasing,
                    g: .ThetaIncreasing,
                    b: .ThetaIncreasing),
                title: L10n.Colors3D.string),

            ColorManager(
                colorModel: .RGB(
                    r: .ThetaIncreasingAndDecreasing,
                    g: .VelocityIn,
                    b: .ThetaIncreasing),
                title: L10n.ColorsWatercolor.string),

            ColorManager(
                colorModel: .RGB(
                    r: .VelocityIn,
                    g: .VelocityOut,
                    b: .VelocityIn),
                title: L10n.ColorsMonsters.string),

            ColorManager(
                colorModel: .HSV(
                    h: .ThetaIncreasingAndDecreasing,
                    s: .Manual(0.33),
                    v: .VelocityOut),
                title: L10n.ColorsPastels.string),

            ColorManager(
                colorModel: .HSV(
                    h: .VelocityIn,
                    s: .VelocityOut,
                    v: .ThetaIncreasingAndDecreasing),
                title: L10n.ColorsMerlin.string),

            ColorManager(
                colorModel: .HSV(
                    h: .Manual(0.0),
                    s: .Manual(0.0),
                    v: .VelocityOut),
                title: L10n.ColorsRegolith.string),

            ColorManager(
                colorModel: .HSV(
                    h: .Manual(0.0),
                    s: .Manual(0.0),
                    v: .ThetaIncreasingAndDecreasing),
                title: L10n.ColorsFilmNoir.string),
        ]
    }
}
