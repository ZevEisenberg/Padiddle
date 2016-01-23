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
    init() {
        let success = NSURLProtocol.registerClass(HelpImageProtocol)
        assert(success)
    }

    lazy var html: String = {
        guard let filePath = NSBundle.mainBundle().pathForResource("help", ofType: "html") else {
            fatalError("Couldn't find help HTML file")
        }

        do {
            let htmlString = try String(contentsOfFile: filePath, encoding: NSUTF8StringEncoding)
            let filledHMTLString = HelpViewModel.populateHTMLString(htmlString)
            return filledHMTLString as String
        } catch let error as NSError {
            fatalError("Error reading in help HTML file: \(error)")
        }
    }()

    static private func populateHTMLString(htmlString: String) -> String {

        var newString = ""
        guard let deviceRange = htmlString.rangeOfString("^device^") else { fatalError() }

        let deviceName = UIDevice.padDeviceName

        newString = htmlString.stringByReplacingCharactersInRange(deviceRange, withString: deviceName as String)

        guard let versionRange = newString.rangeOfString("^version^", options: .BackwardsSearch),
        versionString = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"],
            buildString = NSBundle.mainBundle().infoDictionary?[String(kCFBundleVersionKey)] else { fatalError() }

        let combinedString = "\(versionString) (\(buildString))"
        newString = newString.stringByReplacingCharactersInRange(versionRange, withString: combinedString)

        return newString
    }
}
