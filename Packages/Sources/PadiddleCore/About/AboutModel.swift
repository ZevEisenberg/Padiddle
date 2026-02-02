import Dependencies
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
      #bundle.url(
        forResource: "about",
        withExtension: "html",
        subdirectory: nil,
        localization: code
      )
    }

    var url: URL? = urls.first
    if url == nil {
      print("⚠️ WARNING: Couldn't find About HTML file for \(locale), \(locale.identifier) in \(#bundle) containing \(#bundle.localizations)")
      url = #bundle.url(forResource: "about", withExtension: "html", subdirectory: nil)
    }
    guard let url else {
      fatalError("Couldn't find About HTML file fallback in \(#bundle)")
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

private extension Locale {
  /// "en" instead of "en\_US"
  var bundleLocalizationLanguageCode: String? {
    language.languageCode?.identifier
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
