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
    func colorManagerPicked(_ colorManager: ColorManager)
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

    func indexPathsForItemsOnPageWithIndexPath(_ indexPath: IndexPath) -> [IndexPath] {
        //--------------------------------------------------
        // The layout doesn’t exist yet, so we can’t query
        // its properties, so we use the same information
        // it uses to derive its items per page.
        //--------------------------------------------------
        let itemsPerPage = colsPortrait * rowsPortrait

        let page = (indexPath as IndexPath).item / itemsPerPage

        var indexPaths = [IndexPath]()

        for item in 0..<itemsPerPage {
            indexPaths.append(IndexPath(item: (itemsPerPage * page) + item, section: 0))
        }
        return indexPaths
    }

    func imageForColorManager(_ colorManager: ColorManager) -> UIImage {
        let model = SpiralModel(
            colorManager: colorManager,
            size: CGSize(width: 86, height: 86),
            startRadius: 0,
            spacePerLoop: 1.5,
            thetaRange: 0...(2.0 * .pi * 4.0),
            thetaStep: .pi / 32.0,
            lineWidth: 4.9)

        let image = SpiralImageMaker.image(spiralModel: model)
        return image
    }
}

extension ColorPickerViewModel {
    var colorsToPick: [ColorManager] {
        return [ColorManager(
            colorModel: .hsv(
                h: .thetaIncreasing,
                s: .manual(1.0),
                v: .velocityIn),
            title: L10n.ColorsClassic.string),

            ColorManager(
                colorModel: .hsv(
                    h: .manual(30.0 / 360.0),
                    s: .manual(0.2),
                    v: .thetaIncreasingAndDecreasing),
                title: L10n.ColorsSepia.string),

            ColorManager(
                colorModel: .hsv(
                    h: .manual(0.0),
                    s: .manual(1.0),
                    v: .velocityIn),
                title: L10n.ColorsBlackWidow.string),

            ColorManager(
                colorModel: .rgb(
                    r: .velocityOut,
                    g: .manual(0.45),
                    b: .manual(0.0)),
                title: L10n.ColorsAutumn.string),

            ColorManager(
                colorModel: .hsv(
                    h: .manual(30.0 / 360.0),
                    s: .velocityIn,
                    v: .manual(1.0)),
                title: L10n.ColorsTangerine.string),

            ColorManager(
                colorModel: .rgb(
                    r: .thetaIncreasingAndDecreasing,
                    g: .thetaIncreasing,
                    b: .thetaIncreasing),
                title: L10n.Colors3D.string),

            ColorManager(
                colorModel: .rgb(
                    r: .thetaIncreasingAndDecreasing,
                    g: .velocityIn,
                    b: .thetaIncreasing),
                title: L10n.ColorsWatercolor.string),

            ColorManager(
                colorModel: .rgb(
                    r: .velocityIn,
                    g: .velocityOut,
                    b: .velocityIn),
                title: L10n.ColorsMonsters.string),

            ColorManager(
                colorModel: .hsv(
                    h: .thetaIncreasingAndDecreasing,
                    s: .manual(0.33),
                    v: .velocityOut),
                title: L10n.ColorsPastels.string),

            ColorManager(
                colorModel: .hsv(
                    h: .velocityIn,
                    s: .velocityOut,
                    v: .thetaIncreasingAndDecreasing),
                title: L10n.ColorsMerlin.string),

            ColorManager(
                colorModel: .hsv(
                    h: .manual(0.0),
                    s: .manual(0.0),
                    v: .velocityOut),
                title: L10n.ColorsRegolith.string),

            ColorManager(
                colorModel: .hsv(
                    h: .manual(0.0),
                    s: .manual(0.0),
                    v: .thetaIncreasingAndDecreasing),
                title: L10n.ColorsFilmNoir.string),
        ]
    }
}
