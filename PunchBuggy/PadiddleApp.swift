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
        let url = Bundle.main.url(forResource: "ScreenshotPersistedImage-\(sideLengthPixels)×\(sideLengthPixels)", withExtension: "png")!
        let data = try! Data(contentsOf: url)
        let image = UIImage(data: data)!
        let cgImage = image.cgImage!
        return cgImage
      }
    )
  }
}
