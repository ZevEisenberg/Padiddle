//
//  Defaults.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/18/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import Foundation

struct Defaults {

    static var snapshotMode: Bool {
        UserDefaults.standard.bool(forKey: snapshotKey)
    }

    static var colorPickerSelection: Int {
        get {
            if snapshotMode {
                return snapshotPersistedIndex
            }
            else {
                return (UserDefaults().object(forKey: colorPickerPersistentIndexKey) as? Int) ?? deafultPersistedIndex
            }
        }
        set(newSelection) {
            UserDefaults().set(newSelection, forKey: colorPickerPersistentIndexKey)
        }
    }

    private static let snapshotPersistedIndex = 6
    private static let deafultPersistedIndex = 0

    private static let colorPickerPersistentIndexKey = "ColorPickerIndex"
    private static let snapshotKey = "FASTLANE_SNAPSHOT"

}
