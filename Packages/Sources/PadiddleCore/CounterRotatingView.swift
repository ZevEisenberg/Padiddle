import SwiftUI
import UIKit
import XCTestDynamicOverlay

extension View {
  @ViewBuilder
  func counterRotating(longestSideLength: CGFloat) -> some View {
    CounterRotatingViewControllerRepresentable(
      longestSideLength: longestSideLength,
      content: self
    )
  }
}

private struct CounterRotatingViewControllerRepresentable<Content: View>: UIViewControllerRepresentable {
  let longestSideLength: CGFloat
  let content: Content

  func makeUIViewController(
    context: Context
  ) -> CounterRotatingViewController<Content> {
    CounterRotatingViewController<Content>(
      longestSideLength: longestSideLength,
      content: content
    )
  }

  func updateUIViewController(
    _ uiViewController: CounterRotatingViewController<Content>,
    context: Context
  ) {
    uiViewController.contentViewController.rootView = content
    for constraint in uiViewController.contentSizeConstraints {
      constraint.constant = longestSideLength
    }
  }
}

class CounterRotatingViewController<Content: View>: UIViewController {
  let longestSideLength: CGFloat
  let contentViewController: UIHostingController<Content>
  private let windowNotifyingView = WindowNotifyingView()
  var contentSizeConstraints: [NSLayoutConstraint] = []

  init(longestSideLength: CGFloat, content: Content) {
    self.longestSideLength = longestSideLength
    self.contentViewController = UIHostingController(rootView: content)
    contentViewController.safeAreaRegions = []
    super.init(nibName: nil, bundle: nil)
  }

  override func viewDidLoad() {
    view.addSubview(windowNotifyingView)
    windowNotifyingView.frame = view.bounds
    windowNotifyingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    windowNotifyingView.isHidden = true

    contentViewController.willMove(toParent: self)
    view.addSubview(contentViewController.view)

    contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      contentViewController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      contentViewController.view.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])

    contentSizeConstraints = [
      contentViewController.view.widthAnchor.constraint(equalToConstant: longestSideLength),
      contentViewController.view.heightAnchor.constraint(equalToConstant: longestSideLength),
    ]
    NSLayoutConstraint.activate(contentSizeConstraints)

    contentViewController.didMove(toParent: self)

    windowNotifyingView.didMoveToWindowCallback = { [weak self] window in
      guard let self, let window else {
        return
      }

      guard let statusBarOrientation = window.windowScene?.effectiveGeometry.interfaceOrientation else {
        fatalError("status bar orientation should never be unavailable when the window is non-nil")
      }

      contentViewController.view.transform = statusBarOrientation.counterRotatingTransform
    }

    super.viewDidLoad()
  }

  override func viewWillTransition(
    to size: CGSize,
    with coordinator: any UIViewControllerTransitionCoordinator
  ) {
    // amount of rotation relative to previous status bar orientation
    let targetTransform = coordinator.targetTransform

    // status bar orientation right before this rotation occurred
    guard let statusBarOrientation = view.window?.windowScene?.effectiveGeometry.interfaceOrientation else {
      fatalError("Status bar orientation should never be unavailable during a transition")
    }

    let statusBarTransform = statusBarOrientation.counterRotatingTransform

    let newTransform = targetTransform.inverted().concatenating(statusBarTransform)

    let oldAngle = contentViewController.view.transform.angle.zeroIfCloseToZero
    let newAngle = newTransform.angle.zeroIfCloseToZero
    let delta = newAngle - oldAngle

    coordinator.animate(alongsideTransition: { _ in
      // Note: though this is not explicitly a keyframe animation context, adding keyframes seems to work fine, so let's go with it I guess!
      UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {
        // The midpoint of the two-step rotation animation
        var average = (oldAngle + newAngle) / 2

        // Handle two edge cases that cause undesirable reverse counter-rotation,
        // where the counter-rotating view makes a full 360° or 270° rotation
        // instead of taking the 180° or 90° shortest path.
        // The edge cases are as follows:
        //     1. if the delta is +180° (+π rad)
        //     2. if the delta is ±270° (±3π/2 rad)
        // In both cases, we subtract 180° (π rad) so it will take the shortest path.
        if delta.closeEnough(to: .pi) || abs(delta).closeEnough(to: 3 * .pi / 2) {
          average -= .pi
        }

        self.contentViewController.view.transform = CGAffineTransform(rotationAngle: average.zeroIfCloseToZero)
      }

      UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
        self.contentViewController.view.transform = newTransform
      }
    })
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

private final class WindowNotifyingView: UIView {
  var didMoveToWindowCallback: ((UIWindow?) -> Void) = unimplemented("\(WindowNotifyingView.self).didMoveToWindowCallback")

  override func didMoveToWindow() {
    didMoveToWindowCallback(window)
    super.didMoveToWindow()
  }
}

private extension UIInterfaceOrientation {
  var counterRotatingTransform: CGAffineTransform {
    let newTransform: CGAffineTransform
    switch self {
    case .portrait,
         .unknown:
      newTransform = .identity
    case .portraitUpsideDown:
      newTransform = CGAffineTransform(rotationAngle: .pi)
    case .landscapeLeft:
      newTransform = CGAffineTransform(rotationAngle: .pi / 2)
    case .landscapeRight:
      newTransform = CGAffineTransform(rotationAngle: -.pi / 2)
    @unknown default:
      assertionFailure("Unknown status bar orientation \(readableName)")
      newTransform = .identity
    }
    return newTransform
  }
}

private extension UIInterfaceOrientation {
  var readableName: String {
    switch self {
    case .unknown:
      return "Unknown"
    case .portrait:
      return "Portrait"
    case .portraitUpsideDown:
      return "PortraitUpsideDown"
    case .landscapeLeft:
      return "LandscapeLeft"
    case .landscapeRight:
      return "LandscapeRight"
    @unknown default:
      assertionFailure("Unknown orientation \(self)")
      return "Unknown orientation \(rawValue)"
    }
  }
}
