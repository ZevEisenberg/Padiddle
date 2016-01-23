// Generated using SwiftGen, by O.Halligon — https://github.com/AliSoftware/SwiftGen

import Foundation
import UIKit

extension UIImage {
  enum Asset: String {
    case HelpButton = "HelpButton"
    case PauseButton = "PauseButton"
    case RecordButtonBack = "RecordButtonBack"
    case RecordButtonFront = "RecordButtonFront"
    case ShareButton = "ShareButton"
    case TrashButton = "TrashButton"

    var image: UIImage {
      return UIImage(asset: self)
    }
  }

  convenience init!(asset: Asset) {
    self.init(named: asset.rawValue)
  }
}
