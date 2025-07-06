import Dependencies
import DependenciesMacros
import SwiftUI
import UIKit

struct AboutModel {
  var html: String
  init() async {
    @Dependency(\.locale) var locale

    let languageCodes = [
      locale.identifier,
      locale.bundleLocalizationLanguageCode,
    ].compactMap(\.self)

    let urls = languageCodes.lazy.compactMap { code in
      Bundle.module.url(
        forResource: "about",
        withExtension: "html",
        subdirectory: nil,
        localization: code
      )
    }

    guard let url = urls.first else {
      fatalError("Couldn't find About HTML file for \(locale), \(locale.identifier) in \(Bundle.module) containing \(Bundle.module.localizations)")
    }

    do {
      let htmlString = try String(contentsOf: url, encoding: String.Encoding.utf8)
      let filledHMTLString = await Self.populateHTMLString(htmlString)
      self.html = filledHMTLString
    } catch {
      fatalError("Error reading in About HTML file: \(error)")
    }
  }
}

extension Locale {
  /// "en" instead of "en\_US"
  var bundleLocalizationLanguageCode: String? {
    language.languageCode?.identifier
  }
}

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

        let spinImage = UIImage(systemName: "arrow.trianglehead.2.clockwise")!
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

// InfoDictionary client like the above DeviceClient, but for accessing things like the bundle version:
@DependencyClient
struct InfoDictionaryClient: DependencyKey, Sendable {
  var marketingVersion: @Sendable () async -> String = { unimplemented(placeholder: "0.0.0") }
  var buildNumber: @Sendable () async -> String = { unimplemented(placeholder: "0000") }

  static var liveValue: Self {
    Self(
      marketingVersion: {
        guard let marketingVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
          fatalError("Could not get short version string. Something is badly wrong. Info dictionary: \(String(describing: Bundle.main.infoDictionary))")
        }
        return marketingVersion
      },
      buildNumber: {
        guard let marketingVersion = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String else {
          fatalError("Could not get short version string. Something is badly wrong. Info dictionary: \(String(describing: Bundle.main.infoDictionary))")
        }
        return marketingVersion
      }
    )
  }

  static var testValue: Self {
    Self(
      marketingVersion: { "1.0.0" },
      buildNumber: { "0001" }
    )
  }
}

extension UIDevice {
  var deviceKind: DeviceClient.DeviceKind {
    var deviceName = UIDevice.current.model

    #if targetEnvironment(simulator)
    let range = deviceName.range(
      of: "simulator",
      options: [.anchored, .backwards, .caseInsensitive]
    )

    if range != nil {
      if userInterfaceIdiom == .pad {
        deviceName = "iPad"
      } else {
        deviceName = "iPhone"
      }
    }
    #endif

    return DeviceClient.DeviceKind(rawValue: deviceName)!
  }
}

extension DependencyValues {
  var deviceClient: DeviceClient {
    get { self[DeviceClient.self] }
    set { self[DeviceClient.self] = newValue }
  }

  var infoDictionaryClient: InfoDictionaryClient {
    get { self[InfoDictionaryClient.self] }
    set { self[InfoDictionaryClient.self] = newValue }
  }
}

private extension AboutModel {
  private static func populateHTMLString(_ htmlString: String) async -> String {
    var newString = ""

    // Device Name
    guard let deviceNameRange = htmlString.range(of: "^deviceName^") else {
      fatalError("String should contain device name placeholder")
    }

    @Dependency(\.deviceClient) var deviceClient

    let deviceKind = await deviceClient.deviceKind()

    newString = htmlString.replacingCharacters(in: deviceNameRange, with: deviceKind.rawValue)

    // Version and build number
    guard
      let versionRange = newString.range(of: "^version^", options: .backwards)
    else { fatalError("Something has gone horribly wrong") }

    @Dependency(\.infoDictionaryClient) var infoDictionaryClient

    let combinedString = await "\(infoDictionaryClient.marketingVersion()) (\(infoDictionaryClient.buildNumber()))"
    newString = newString.replacingCharacters(in: versionRange, with: combinedString)

    return newString
  }
}
