//
//  Defaults.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/18/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import Foundation

private let colorPickerPersistentIndexKey = "ColorPickerIndex"

#if SCREENSHOTS
let defaultColorPickerPersistentIndex = 6
    #else
let defaultColorPickerPersistentIndex = 0
#endif

struct Defaults {
    static var colorPickerSelection: Int {
        get {
            return (NSUserDefaults().objectForKey(colorPickerPersistentIndexKey) as? Int) ?? defaultColorPickerPersistentIndex
        }
        set(newSelection) {
            NSUserDefaults().setInteger(newSelection, forKey: colorPickerPersistentIndexKey)
        }
    }
}
