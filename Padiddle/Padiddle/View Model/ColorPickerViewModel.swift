//
//  ColorPickerViewModel.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/17/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import CoreGraphics.CGBase
import UIKit

protocol ColorPickerViewModelDelegate: AnyObject {

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
            title: L10n.colorsClassic),

            ColorManager(
                colorModel: .hsv(
                    h: .manual(30.0 / 360.0),
                    s: .manual(0.2),
                    v: .thetaIncreasingAndDecreasing),
                title: L10n.colorsSepia),

            ColorManager(
                colorModel: .hsv(
                    h: .manual(0.0),
                    s: .manual(1.0),
                    v: .velocityIn),
                title: L10n.colorsBlackWidow),

            ColorManager(
                colorModel: .rgb(
                    r: .velocityOut,
                    g: .manual(0.45),
                    b: .manual(0.0)),
                title: L10n.colorsAutumn),

            ColorManager(
                colorModel: .hsv(
                    h: .manual(30.0 / 360.0),
                    s: .velocityIn,
                    v: .manual(1.0)),
                title: L10n.colorsTangerine),

            ColorManager(
                colorModel: .rgb(
                    r: .thetaIncreasingAndDecreasing,
                    g: .thetaIncreasing,
                    b: .thetaIncreasing),
                title: L10n.colors3D),

            ColorManager(
                colorModel: .rgb(
                    r: .thetaIncreasingAndDecreasing,
                    g: .velocityIn,
                    b: .thetaIncreasing),
                title: L10n.colorsWatercolor),

            ColorManager(
                colorModel: .rgb(
                    r: .velocityIn,
                    g: .velocityOut,
                    b: .velocityIn),
                title: L10n.colorsMonsters),

            ColorManager(
                colorModel: .hsv(
                    h: .thetaIncreasingAndDecreasing,
                    s: .manual(0.33),
                    v: .velocityOut),
                title: L10n.colorsPastels),

            ColorManager(
                colorModel: .hsv(
                    h: .velocityIn,
                    s: .velocityOut,
                    v: .thetaIncreasingAndDecreasing),
                title: L10n.colorsMerlin),

            ColorManager(
                colorModel: .hsv(
                    h: .manual(0.0),
                    s: .manual(0.0),
                    v: .velocityOut),
                title: L10n.colorsRegolith),

            ColorManager(
                colorModel: .hsv(
                    h: .manual(0.0),
                    s: .manual(0.0),
                    v: .thetaIncreasingAndDecreasing),
                title: L10n.colorsFilmNoir),
        ]
    }

}
