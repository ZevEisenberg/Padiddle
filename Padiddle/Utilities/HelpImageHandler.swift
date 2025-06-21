import Foundation
import UIKit.UIImage
import WebKit

/// Handle asset://assetName requests from WKWebView and return the appropriate
/// image asset. Built with the help of https://medium.com/glose-team/custom-scheme-handling-and-wkwebview-in-ios-11-72bc5113e344
class HelpImageHandler: NSObject, WKURLSchemeHandler {
  static var colorButtonImage: UIImage?

  func webView(_: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
    guard
      let url = urlSchemeTask.request.url,
      url.scheme == "asset",
      let imageName = url.host
    else {
      return
    }

    let image: UIImage? = switch imageName {
    case "recordButton":
      UIImage.recordButtonImage()
    case "colorButton":
      HelpImageHandler.colorButtonImage
    default:
      UIImage(named: imageName)
    }

    guard let image, let imageData = image.pngData() else {
      return
    }

    let urlResponse = URLResponse(url: url, mimeType: "image/png", expectedContentLength: imageData.count, textEncodingName: nil)
    urlSchemeTask.didReceive(urlResponse)
    urlSchemeTask.didReceive(imageData)
    urlSchemeTask.didFinish()
  }

  func webView(_: WKWebView, stop _: WKURLSchemeTask) {}
}
