//
//  HelpImageProtocol.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 1/22/16.
//  Copyright © 2016 Zev Eisenberg. All rights reserved.
//

import Foundation
import UIKit.UIImage

class HelpImageProtocol: URLProtocol {

    static var colorButtonImage: UIImage?

    override class func canInit(with request: URLRequest) -> Bool {
        return request.url?.pathExtension == "asset"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let client = client, let url = request.url else { return }

        guard let lastPathComponent = request.url?.lastPathComponent, lastPathComponent.characters.count > 0 else { return }

        let imageName = (lastPathComponent as NSString).deletingPathExtension

        var image: UIImage?
        switch imageName {
        case "recordButton":
            image = UIImage.recordButtonImage()
        case "colorButton":
            image = HelpImageProtocol.colorButtonImage
        default:
            image = UIImage(named: imageName)
        }

        guard let yesImage = image, let imageData = UIImagePNGRepresentation(yesImage) else { return }

        let headers = ["Content-Type": "image/png"]

        guard let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: headers) else { return }

        client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowedInMemoryOnly)

        client.urlProtocol(self, didLoad: imageData)
    }

    override func stopLoading() {
        // We send all the data at once, so there is nothing to do here.
    }
}
