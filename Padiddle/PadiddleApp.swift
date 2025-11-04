import Dependencies
import PadiddleCore
import SwiftUI

@main
struct PadiddleApp: App {
  var body: some Scene {
    WindowGroup {
      RootView()
    }
  }
}

extension ImageIO: @retroactive DependencyKey {
  public static var liveValue: Self {
    Self(
      fetchImage: { sideLengthPixels in
        guard let url = Bundle.main.url(
          forResource: "ScreenshotPersistedImage-\(sideLengthPixels)×\(sideLengthPixels)",
          withExtension: "png"
        ) else {
          struct ScreenshotNotFound: Error {
            let sideLengthPixels: Int
          }
          throw ScreenshotNotFound(sideLengthPixels: sideLengthPixels)
        }
        let data = try Data(contentsOf: url)
        guard let image = UIImage(data: data) else {
          struct CouldNotMakeImageFromData: Error {}
          throw CouldNotMakeImageFromData()
        }
        guard let cgImage = image.cgImage else {
          struct CouldNotMakeCGImageFromImage: Error {}
          throw CouldNotMakeCGImageFromImage()
        }
        return cgImage
      }
    )
  }
}
