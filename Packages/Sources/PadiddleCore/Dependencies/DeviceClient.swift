import Dependencies
import DependenciesMacros
import SwiftUI
import UIKit

@DependencyClient
struct DeviceClient: DependencyKey, Sendable {
  enum DeviceKind: String {
    case iPad
    case iPhone

    private var deviceImageSymbolName: String {
      switch self {
      case .iPad:
        "ipad"
      case .iPhone:
        "iphone"
      }
    }

    var deviceImage: Image {
      Image(systemName: deviceImageSymbolName)
    }

    var deviceUIImage: UIImage {
      UIImage(systemName: deviceImageSymbolName)!
    }

    func deviceSpinImage(
      displayScale: CGFloat,
      colorScheme: ColorScheme
    ) -> UIImage {
      let deviceImageToDraw = deviceUIImage
        .applyingSymbolConfiguration(.init(weight: .ultraLight))!
        .withTintColor(colorScheme == .dark ? .white : .black)

      let outputImageWidth = 200.0
      let originalImageSize = deviceImageToDraw.size
      let scaleUpMultiplier = outputImageWidth / originalImageSize.width

      let sizeToRender = CGSize(
        width: outputImageWidth,
        height: originalImageSize.height * scaleUpMultiplier
      )
      let format = UIGraphicsImageRendererFormat()
      format.scale = displayScale
      let renderer = UIGraphicsImageRenderer(
        size: sizeToRender,
        format: format
      )
      let result = renderer.image { rendererContext in
        deviceImageToDraw.draw(
          in: CGRect(
            origin: .zero,
            size: sizeToRender
          )
        )

        let spinImage = UIImage(systemName: "arrow.trianglehead.2.clockwise.rotate.90")!
          .applyingSymbolConfiguration(.init(weight: .regular))!
          .withTintColor(UIColor(resource: .Toolbar.RecordButton.record))
          .applyingSymbolConfiguration(.init(pointSize: 75))!

        rendererContext.cgContext.translateBy(
          x: sizeToRender.width / 2 - spinImage.size.width / 2,
          y: sizeToRender.height / 2 - spinImage.size.height / 2
        )
        spinImage.draw(at: .zero)
      }
      return result
    }
  }

  var deviceKind: @Sendable @MainActor () -> DeviceKind = { .iPhone }

  static var liveValue: Self {
    Self(
      deviceKind: {
        UIDevice.current.deviceKind
      }
    )
  }

  // testValue
  static var testValue: Self {
    Self(
      deviceKind: { .iPhone }
    )
  }
}

extension DependencyValues {
  var deviceClient: DeviceClient {
    get { self[DeviceClient.self] }
    set { self[DeviceClient.self] = newValue }
  }
}
