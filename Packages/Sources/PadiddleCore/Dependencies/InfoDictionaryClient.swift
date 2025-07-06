import Dependencies
import DependenciesMacros
import Foundation

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

extension DependencyValues {
  var infoDictionaryClient: InfoDictionaryClient {
    get { self[InfoDictionaryClient.self] }
    set { self[InfoDictionaryClient.self] = newValue }
  }
}
