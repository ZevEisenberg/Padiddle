import SwiftUI
import UIKit

struct ScreenMetrics: Equatable {
  /// The size of the screen in points. Equal to `screen.bounds.size`.
  var size: CGSize

  /// The pixel scale of the screen.
  var scale: CGFloat
}

extension View {
  @ViewBuilder
  func onScreenChange(callback: @escaping (ScreenMetrics?) -> Void) -> some View {
    background {
      ScreenReader(screenChanged: callback)
        .opacity(0) // .hidden() prevents didMoveToWindow from being called
    }
  }
}

/// Inspired by https://github.com/divadretlaw/WindowReader and https://github.com/divadretlaw/WindowSceneReader
private struct ScreenReader: UIViewRepresentable {
  let screenChanged: (ScreenMetrics?) -> Void

  func makeUIView(context: Context) -> ScreenReportingView {
    ScreenReportingView(screenChanged: screenChanged)
  }

  func updateUIView(_ view: ScreenReportingView, context: Context) {
    view.screenChanged = screenChanged
  }
}

private final class ScreenReportingView: UIView {
  var screenChanged: (ScreenMetrics?) -> Void

  /// Observes the window scene's geometry, which changes when the scene moves to another display
  /// (for example, folding a Duo) or is resized.
  private var geometryObservation: NSKeyValueObservation?

  init(screenChanged: @escaping (ScreenMetrics?) -> Void) {
    self.screenChanged = screenChanged
    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    geometryObservation = window?.windowScene?.observe(\.effectiveGeometry) { [weak self] scene, _ in
      MainActor.assumeIsolated {
        self?.reportScreen(of: scene)
      }
    }
    reportScreen(of: window?.windowScene)
  }

  private func reportScreen(of windowScene: UIWindowScene?) {
    screenChanged(
      windowScene.map {
        ScreenMetrics(
          size: $0.screen.bounds.size,
          scale: $0.screen.scale
        )
      }
    )
  }
}
