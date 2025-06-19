import Anchorage
import UIKit

public extension UIInterfaceOrientation {
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

func transformForStatusBarOrientation(_ statusBarOrientation: UIInterfaceOrientation) -> CGAffineTransform {
  let newTransform: CGAffineTransform
  switch statusBarOrientation {
  case .portrait,
       .unknown:
    newTransform = CGAffineTransform.identity
  case .portraitUpsideDown:
    newTransform = CGAffineTransform(rotationAngle: .pi)
  case .landscapeLeft:
    newTransform = CGAffineTransform(rotationAngle: .pi / 2)
  case .landscapeRight:
    newTransform = CGAffineTransform(rotationAngle: -.pi / 2)
  @unknown default:
    assertionFailure("Unknown status bar orientation \(statusBarOrientation.readableName)")
    newTransform = .identity
  }
  return newTransform
}

private final class WindowNotifyingView: UIView {
  var didMoveToWindowCallback: ((UIWindow?) -> Void)!

  override func didMoveToWindow() {
    didMoveToWindowCallback(window)
    super.didMoveToWindow()
  }
}

class CounterRotatingViewController: UIViewController {
  let screenLongestSideLength: CGFloat

  init(screenLongestSideLength: CGFloat) {
    self.screenLongestSideLength = screenLongestSideLength
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable) required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private let _counterRotatingView = WindowNotifyingView(axId: "counterRotatingView")

  var counterRotatingView: UIView {
    _counterRotatingView
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.addSubview(counterRotatingView)

    counterRotatingView.centerXAnchor == view.centerXAnchor
    counterRotatingView.centerYAnchor == view.centerYAnchor
    counterRotatingView.sizeAnchors == CGSize(width: screenLongestSideLength, height: screenLongestSideLength)

    _counterRotatingView.didMoveToWindowCallback = { [weak self] window in
      guard let self, let window else {
        return
      }
      guard let statusBarOrientation = window.windowScene?.effectiveGeometry.interfaceOrientation else {
        fatalError("status bar orientation should never be unavailable when the window is non-nil")
      }

      counterRotatingView.transform = transformForStatusBarOrientation(statusBarOrientation)
    }
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    // amount of rotation relative to previous status bar orientation
    let targetTransform = coordinator.targetTransform

    // status bar orientation right before this rotation occurred
    guard let statusBarOrientation = view.window?.windowScene?.effectiveGeometry.interfaceOrientation else {
      fatalError("Status bar orientation should never be unavailable during a transition")
    }
    let statusBarTransform = transformForStatusBarOrientation(statusBarOrientation)

    let newTransform = targetTransform.inverted().concatenating(statusBarTransform)

    let oldAngle = counterRotatingView.transform.angle.reasonableValue
    let newAngle = newTransform.angle.reasonableValue
    let delta = newAngle - oldAngle

    coordinator.animate { _ in
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

        self.counterRotatingView.transform = CGAffineTransform(rotationAngle: average.reasonableValue)
      }

      UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
        self.counterRotatingView.transform = newTransform
      }
    }

    super.viewWillTransition(to: size, with: coordinator)
  }
}
