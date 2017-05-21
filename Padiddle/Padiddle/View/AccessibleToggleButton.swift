//
//  AccessibleToggleButton.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 5/21/17.
//  Copyright © 2017 Zev Eisenberg. All rights reserved.
//

import UIKit

class AccessibleToggleButton: UIButton {

    var accessibilityLabels: (normal: String, selected: String)?

    override var accessibilityLabel: String? {
        get {
            guard let accessibilityLabels = accessibilityLabels else {
                return super.accessibilityLabel
            }

            return isSelected ? accessibilityLabels.selected : accessibilityLabels.normal
        }
        set {
            accessibilityLabels = newValue.flatMap { (normal: $0, selected: $0) }
        }
    }

}
