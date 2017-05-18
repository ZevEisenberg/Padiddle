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
        switch current.userInterfaceIdiom {
        case .pad:
            return 22
        default:
            return 25
        }
    }

    @nonobjc class var deviceName: String {
        var deviceName = current.model

        if isSimulator {
            let range = deviceName.range(of: "simulator",
                options: [.anchored, .backwards, .caseInsensitive]
            )

            if range != nil {
                if current.userInterfaceIdiom == .pad {
                    deviceName = "iPad"
                }
                else {
                    deviceName = "iPhone"
                }
            }
        }

        return deviceName
    }

    @nonobjc class var deviceImage: UIImage {
        switch deviceName {
        case "iPad": return #imageLiteral(resourceName: "iPad")
        case "iPhone": return #imageLiteral(resourceName: "iPhone")
        default: fatalError("Should only get one or the other")
        }
    }

    class var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }

}
