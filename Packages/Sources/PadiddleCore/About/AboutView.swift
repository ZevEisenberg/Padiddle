import _WebKit_SwiftUI
import Dependencies
import Models
import Sharing
import SwiftUI

public struct AboutView: View {
  /// Pass this in because the About view is presented in a popover, and it is the size class of the parent view that we care about.
  let horizontalSizeClass: UserInterfaceSizeClass
  @State private var webPage = WebPage()

  @Environment(\.dismiss) private var dismiss
  @Environment(\.displayScale) private var displayScale
  @Environment(\.colorScheme) private var colorScheme

  private struct ContentInvalidator: Hashable {
    let displayScale: CGFloat
    let colorScheme: ColorScheme
  }

  public init(horizontalSizeClass: UserInterfaceSizeClass) {
    self.horizontalSizeClass = horizontalSizeClass
  }

  public var body: some View {
    NavigationStack {
      WebView(webPage)
        .navigationTitle(Text(.about))
        .navigationBarTitleDisplayMode(.inline)
        .scrollIndicatorsFlash(onAppear: true)
        .toolbar {
          Button(role: .close) {
            dismiss()
          }
        }
        // Stop bottom of web view from getting clipped by nav stack. Apparently.
        .ignoresSafeArea(edges: .bottom)
    }
    .task(id: ContentInvalidator(displayScale: displayScale, colorScheme: colorScheme)) {
      await loadContent()
    }
  }
}

extension WebPage.Configuration {
  static func padiddle(
    deviceKind: DeviceClient.DeviceKind,
    displayScale: CGFloat,
    colorScheme: ColorScheme
  ) -> WebPage.Configuration {
    var configuration = WebPage.Configuration()
    configuration.urlSchemeHandlers = [
      URLScheme("padiddle-asset")!: AboutAssetHandler(
        deviceKind: deviceKind,
        displayScale: displayScale,
        colorScheme: colorScheme
      ),
    ]
    return configuration
  }
}

private extension AboutView {
  func loadContent() async {
    let html = await AboutModel().html
    let baseURL = URL(string: "localhost")!
    let deviceKind: DeviceClient.DeviceKind = switch horizontalSizeClass {
    case .compact:
      .iPhone
    case .regular:
      .iPad
    @unknown default:
      .iPhone
    }
    webPage = WebPage(
      configuration: .padiddle(
        deviceKind: deviceKind,
        displayScale: displayScale,
        colorScheme: colorScheme
      )
    )
    webPage.load(html: html, baseURL: baseURL)
  }
}

#Preview {
  @Previewable @Environment(\.horizontalSizeClass) var horizontalSizeClass
  @Previewable @Shared(.colorButtonImage) var colorButtonImage
  @Previewable @Environment(\.displayScale) var displayScale
  withDependencies {
    $0.locale = Locale(identifier: "en")
    $colorButtonImage.withLock {
      $0 = SpiralImageMaker.image(
        // TODO: constantize
        spiralModel: SpiralModel(
          colorGenerator: .classic,
          size: .square(sideLength: 36),
          startRadius: 0,
          spacePerLoop: 0.7,
          thetaRange: 0...(2.0 * .pi * 4.0),
          thetaStep: .pi / 16.0,
          lineWidth: 2.3
        ),
        scale: displayScale
      )
    }
  } operation: {
    AboutView(horizontalSizeClass: horizontalSizeClass!)
  }
}
