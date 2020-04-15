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
            return 30
        default:
            return 30
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
        case "iPhone", "iPod touch": return #imageLiteral(resourceName: "iPhone")
        default: fatalError("Should only get one or the other, but device name was \(deviceName)")
        }
    }

    @nonobjc class var spinPromptImage: (image: UIImage, insets: UIEdgeInsets) {
        // Inset values are measured from Sketch
        switch deviceName {
        case "iPad": return (#imageLiteral(resourceName: "iPad Spin Prompt"), UIEdgeInsets(top: 32, left: 14, bottom: 31, right: 14))
        case "iPhone", "iPod touch": return (#imageLiteral(resourceName: "iPhone Spin Prompt"), UIEdgeInsets(top: 45, left: 12, bottom: 45, right: 12))
        default: fatalError("Should only get one or the other, but device name was \(deviceName)")
        }
    }

    class var isSimulator: Bool {
        TARGET_OS_SIMULATOR != 0
    }

}
