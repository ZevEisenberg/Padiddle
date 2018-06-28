//
//  HelpViewModel.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 1/22/16.
//  Copyright © 2016 Zev Eisenberg. All rights reserved.
//

import Foundation
import UIKit.UIImage

struct HelpViewModel {

    lazy var html: String = {
        guard let filePath = Bundle.main.path(forResource: "help", ofType: "html") else {
            fatalError("Couldn't find help HTML file")
        }

        do {
            let htmlString = try String(contentsOfFile: filePath, encoding: String.Encoding.utf8)
            let filledHMTLString = HelpViewModel.populateHTMLString(htmlString)
            return filledHMTLString
        }
        catch let error {
            Log.error("failed to read help HTML file: \(error)")
            fatalError("Error reading in help HTML file: \(error)")
        }
    }()

    static private func populateHTMLString(_ htmlString: String) -> String {

        var newString = ""

        // Device Name
        guard let deviceNameRange = htmlString.range(of: "^deviceName^") else { fatalError() }

        let deviceName = UIDevice.deviceName

        newString = htmlString.replacingCharacters(in: deviceNameRange, with: deviceName)

        // Device Image
        guard let deviceImageRange = newString.range(of: "^deviceImage^") else { fatalError() }

        newString = newString.replacingCharacters(in: deviceImageRange, with: deviceName)

        // Device Image Width
        let deviceImage = UIDevice.deviceImage

        let nativeWidth = deviceImage.size.width

        guard let imageWidthRange = newString.range(of: "^maxDeviceImageWidthPoints^") else { fatalError() }
        newString = newString.replacingCharacters(in: imageWidthRange, with: String(describing: nativeWidth))

        // Version Number
        guard let versionRange = newString.range(of: "^version^", options: .backwards),
        let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"],
            let buildString = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] else { fatalError() }

        let combinedString = "\(versionString) (\(buildString))"
        newString = newString.replacingCharacters(in: versionRange, with: combinedString)

        return newString
    }

}
