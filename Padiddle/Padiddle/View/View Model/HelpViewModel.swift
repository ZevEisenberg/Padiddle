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
            var htmlString = try NSMutableString(contentsOfFile: filePath, encoding: NSUTF8StringEncoding)
            HelpViewModel.populateString(htmlString)
            return htmlString as String
        } catch let error as NSError {
            fatalError("Error reading in help HTML file: \(error)")
        }
    }()

    static private func populateString(string: NSMutableString) {
        // TODO: populate HTML string
    }
}
