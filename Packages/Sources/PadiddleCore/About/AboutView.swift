import Dependencies
import Models
import Sharing
import SwiftUI
import WebKit

public struct AboutView: View {
  /// Pass this in because the About view is presented in a popover, and it is the size class of the parent view that we care about.
  let horizontalSizeClass: UserInterfaceSizeClass

  @Shared(.colorGenerator) var colorGenerator

  @State private var webPage = WebPage()

  @Environment(\.dismiss) private var dismiss
  @Environment(\.displayScale) private var displayScale
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.openURL) private var openURL

  private struct ContentInvalidator: Hashable {
    let colorGenerator: ColorGenerator
    let displayScale: CGFloat
    let colorScheme: ColorScheme
  }

  public init(horizontalSizeClass: UserInterfaceSizeClass) {
    self.horizontalSizeClass = horizontalSizeClass
  }

  public var body: some View {
    NavigationStack {
      WebView(webPage)
        .scrollBounceBehavior(.basedOnSize)
        .navigationTitle(Text(.about))
        .navigationBarTitleDisplayMode(.inline)
        .scrollIndicatorsFlash(onAppear: true)
        .toolbar {
          Button(role: .close) {
            dismiss()
          }
          .accessibilityIdentifier("aboutViewClose")
        }
        // Stop bottom of web view from getting clipped by nav stack. Apparently.
        .ignoresSafeArea(edges: .bottom)
    }
    .task(
      id: ContentInvalidator(
        colorGenerator: Shared(.colorGenerator).wrappedValue,
        displayScale: displayScale,
        colorScheme: colorScheme
      )
    ) {
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
    @Shared(.colorGenerator) var colorGenerator

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
      ),
      navigationDecider: NavigationDecider(openURL: openURL)
    )
    webPage.load(html: html, baseURL: baseURL)
  }
}

private struct NavigationDecider: WebPage.NavigationDeciding {
  let openURL: OpenURLAction

  func decidePolicy(
    for response: WebPage.NavigationResponse
  ) async -> WKNavigationResponsePolicy {
    await withCheckedContinuation { continuation in
      if let url = response.response.url {
        openURL(url, completion: { didOpen in
          continuation.resume(returning: didOpen ? .cancel : .allow)
        })
      } else {
        continuation.resume(returning: .allow)
      }
    }
  }
}

#Preview {
  @Previewable @Environment(\.horizontalSizeClass) var horizontalSizeClass
  @Previewable @Environment(\.displayScale) var displayScale
  withDependencies {
    $0.locale = Locale(identifier: "en")
  } operation: {
    AboutView(horizontalSizeClass: horizontalSizeClass!)
  }
}
