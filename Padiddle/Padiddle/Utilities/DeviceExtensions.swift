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

    class var padDeviceName: NSString {
        var deviceName = currentDevice().model


        if runningOnSimulator {
            let range = deviceName.rangeOfString("simulator",
                options: [.AnchoredSearch, .BackwardsSearch, .CaseInsensitiveSearch]
            )

            if range != nil {
                if currentDevice().userInterfaceIdiom == .Pad {
                    deviceName = "iPad"
                } else {
                    deviceName = "iPhone"
                }
            }
        }

        return deviceName
    }

    private class var runningOnSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }
}
