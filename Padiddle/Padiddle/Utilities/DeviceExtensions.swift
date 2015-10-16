//
//  TraitCollectionExtensions.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 10/7/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit

extension UIDevice {
    class var gyroMaxValue: CGFloat {
        switch currentDevice().userInterfaceIdiom {
        case .Pad:
            return 22
        default:
            return 25
        }
    }
}
