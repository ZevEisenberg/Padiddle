// Generated using SwiftGen, by O.Halligon — https://github.com/AliSoftware/SwiftGen

#if os(iOS)
  import UIKit.UIImage
  typealias Image = UIImage
#elseif os(OSX)
  import AppKit.NSImage
  typealias Image = NSImage
#endif

enum Asset: String {
  case HelpButton = "HelpButton"
  case IPad = "iPad"
  case IPhone = "iPhone"
  case PauseButton = "PauseButton"
  case RecordButtonBack = "RecordButtonBack"
  case RecordButtonFront = "RecordButtonFront"
  case ShareButton = "ShareButton"
  case TrashButton = "TrashButton"

  var image: Image {
    return Image(asset: self)
  }
}

extension Image {
  convenience init!(asset: Asset) {
    self.init(named: asset.rawValue)
  }
}
