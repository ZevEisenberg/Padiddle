//
//  AccessibilityIdentifierExtensions.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 6/26/16.
//  Copyright © 2016 Zev Eisenberg. All rights reserved.
//

import UIKit

extension UIView {

    convenience init(axId accessibilityIdentifier: String) {
        self.init()
        self.accessibilityIdentifier = accessibilityIdentifier
    }

}

extension UIButton {

    public convenience init(type buttonType: UIButtonType, axId accessibilityIdentifier: String) {
        self.init(type: buttonType)
        self.accessibilityIdentifier = accessibilityIdentifier
    }

}
