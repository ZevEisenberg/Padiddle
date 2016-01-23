//
//  HelpImageProtocol.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 1/22/16.
//  Copyright © 2016 Zev Eisenberg. All rights reserved.
//

import Foundation
import UIKit.UIImage

class HelpImageProtocol: NSURLProtocol {

    static var colorButtonImage: UIImage?

    override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        return request.URL?.pathExtension == "asset"
    }

    override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }

    override func startLoading() {
        guard let client = client, url = request.URL else { return }

        guard let lastPathComponent = request.URL?.lastPathComponent
            where lastPathComponent.characters.count > 0 else { return }

        let imageName = (lastPathComponent as NSString).stringByDeletingPathExtension

        var image: UIImage?
        switch imageName {
        case "recordButton":
            image = UIImage.recordButtonImage()
        case "colorButton":
            image = HelpImageProtocol.colorButtonImage
        default:
            image = UIImage(named: imageName)
        }

        guard let yesImage = image, imageData = UIImagePNGRepresentation(yesImage) else { return }

        let headers = ["Content-Type" : "image/png"]

        guard let response = NSHTTPURLResponse(
            URL: url,
            statusCode: 200,
            HTTPVersion: "HTTP/1.1",
            headerFields: headers) else { return }

        client.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .AllowedInMemoryOnly)

        client.URLProtocol(self, didLoadData: imageData)
    }

    override func stopLoading() {
        // We send all the data at once, so there is nothing to do here.
    }
}
