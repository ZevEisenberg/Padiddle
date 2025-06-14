//
//  HelpImageProtocol.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 1/22/16.
//  Copyright © 2016 Zev Eisenberg. All rights reserved.
//

import Foundation
import UIKit.UIImage
import WebKit

/// Handle asset://assetName requests from WKWebView and return the appropriate
/// image asset. Built with the help of https://medium.com/glose-team/custom-scheme-handling-and-wkwebview-in-ios-11-72bc5113e344
class HelpImageHandler: NSObject, WKURLSchemeHandler {

    static var colorButtonImage: UIImage?

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard
            let url = urlSchemeTask.request.url,
            url.scheme == "asset",
            let imageName = url.host
            else { return }

        var image: UIImage?
        switch imageName {
        case "recordButton":
            image = UIImage.recordButtonImage()
        case "colorButton":
            image = HelpImageHandler.colorButtonImage
        default:
            image = UIImage(named: imageName)
        }

        guard
            let existingImage = image,
            let imageData = existingImage.pngData()
            else { return }

        let urlResponse = URLResponse(url: url, mimeType: "image/png", expectedContentLength: imageData.count, textEncodingName: nil)
        urlSchemeTask.didReceive(urlResponse)
        urlSchemeTask.didReceive(imageData)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
    }

}
