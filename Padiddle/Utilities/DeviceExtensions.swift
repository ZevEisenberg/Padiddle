import UIKit

extension UIDevice {
  class var gyroMaxValue: CGFloat {
    switch current.userInterfaceIdiom {
    case .pad:
      return 30
    default:
      return 30
    }
  }

  @nonobjc class var deviceName: String {
    var deviceName = current.model

    #if targetEnvironment(simulator)
    let range = deviceName.range(
      of: "simulator",
      options: [.anchored, .backwards, .caseInsensitive]
    )

    if range != nil {
      if current.userInterfaceIdiom == .pad {
        deviceName = "iPad"
      } else {
        deviceName = "iPhone"
      }
    }
    #endif

    return deviceName
  }

  @nonobjc class var deviceImage: UIImage {
    switch deviceName {
    case "iPad":
      UIImage(resource: .iPad)
    case "iPhone",
         "iPod touch":
      UIImage(resource: .iPhone)
    default:
      fatalError("Should only get one or the other, but device name was \(deviceName)")
    }
  }

  @nonobjc class var spinPromptImage: (image: UIImage, insets: UIEdgeInsets) {
    // Inset values are measured from Sketch
    switch deviceName {
    case "iPad":
      (UIImage(resource: .iPadSpinPrompt), UIEdgeInsets(top: 32, left: 14, bottom: 31, right: 14))
    case "iPhone",
         "iPod touch":
      (UIImage(resource: .iPhoneSpinPrompt), UIEdgeInsets(top: 45, left: 12, bottom: 45, right: 12))
    default:
      fatalError("Should only get one or the other, but device name was \(deviceName)")
    }
  }
}
