import Dependencies
import Foundation
import Sharing
import SwiftUI
import UIKit.UIImage
import WebKit

/// Handle `padiddle-asset://assetName` requests from `WebView` and return the appropriate
/// image asset. Built with the help of https://medium.com/glose-team/custom-scheme-handling-and-wkwebview-in-ios-11-72bc5113e344
struct AboutAssetHandler: URLSchemeHandler {
  var deviceKind: DeviceClient.DeviceKind
  var displayScale: CGFloat
  var colorScheme: ColorScheme

  func reply(
    for request: URLRequest
  ) -> AsyncThrowingStream<URLSchemeTaskResult, any Error> {
    AsyncThrowingStream { continuation in
      guard
        let url = request.url,
        url.scheme == "padiddle-asset",
        let imageName = url.host
      else {
        struct VeryBadness: Error {}
        continuation.finish(throwing: VeryBadness())
        return
      }

      #warning("TODO: figure out how to get liquid glass images in here. or. Something???")
      let image: UIImage?
      switch imageName {
      case "recordButton":
        image = UIImage(systemName: "record.circle")!
      case "colorButton":
        @SharedReader(.colorButtonImage) var colorButtonImage
        image = colorButtonImage
      case "deviceImage":
        image = deviceKind.deviceSpinImage(displayScale: displayScale, colorScheme: colorScheme)
      default:
        image = nil
      }

      guard let image, let imageData = image.pngData() else {
        return
      }

      let response = URLResponse(
        url: url,
        mimeType: "image/png",
        expectedContentLength: imageData.count,
        textEncodingName: nil
      )
      continuation.yield(.response(response))

      continuation.yield(.data(imageData))
    }
  }
}

extension SharedKey where Self == InMemoryKey<UIImage>.Default {
  static var colorButtonImage: Self {
    Self[.inMemory("colorButtonImage"), default: UIImage(systemName: "square")!]
  }
}
