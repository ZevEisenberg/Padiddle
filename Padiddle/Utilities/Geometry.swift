import CoreGraphics.CGGeometry
import UIKit.UIScreen

nonisolated
extension CGPoint {
  static func distanceBetween(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
    if p1.equalTo(p2) {
      0
    } else {
      hypot(p1.x - p2.x, p1.y - p2.y)
    }
  }

  static func lineIntersection(m1: CGFloat, b1: CGFloat, m2: CGFloat, b2: CGFloat) -> CGPoint? {
    if m1 == m2 {
      // lines are parallel
      return nil
    }

    let returnX = (b2 - b1) / (m1 - m2)

    let returnY = m1 * returnX + b1

    return CGPoint(x: returnX, y: returnY)
  }
}

nonisolated extension CGSize {
  static func max(_ size1: CGSize, _ size2: CGSize) -> CGSize {
    let maxWidth = Swift.max(size1.width, size2.width)
    let maxHeight = Swift.max(size1.height, size2.height)
    return CGSize(width: maxWidth, height: maxHeight)
  }

  static func square(sideLength: CGFloat) -> Self {
    CGSize(width: sideLength, height: sideLength)
  }
}

nonisolated
extension CGRect {
  func centerSmallerRect(_ smallerRect: CGRect) -> CGRect {
    assert(smallerRect.width <= width)
    assert(smallerRect.height <= height)
    assert(smallerRect.origin == .zero)
    assert(origin == .zero)

    let newRect = smallerRect.offsetBy(
      dx: (width - smallerRect.width) / 2,
      dy: (height - smallerRect.height) / 2
    )

    return newRect
  }
}

nonisolated
extension CGPoint {
  func screenPixelsIntegral(forScreenScale screenScale: CGFloat) -> CGPoint {
    var newX = x
    var newY = y

    // integralize to screen pixels
    newX *= screenScale
    newY *= screenScale

    newX = round(newX)
    newY = round(newY)

    newX /= screenScale
    newY /= screenScale

    return CGPoint(x: newX, y: newY)
  }

  func offsetBy(dx: CGFloat, dy: CGFloat) -> CGPoint {
    CGPoint(x: x + dx, y: y + dy)
  }
}

nonisolated
extension CGAffineTransform {
  var angle: CGFloat {
    atan2(b, a)
  }
}

nonisolated
extension UIInterfaceOrientation {
  var imageRotation: (orientation: UIImage.Orientation, rotation: CGFloat) {
    let rotation: CGFloat
    let imageOrientation: UIImage.Orientation

    switch self {
    case .landscapeLeft:
      rotation = -CGFloat.pi / 2.0
      imageOrientation = .right
    case .landscapeRight:
      rotation = .pi / 2.0
      imageOrientation = .left
    case .portraitUpsideDown:
      rotation = .pi
      imageOrientation = .down
    case .portrait,
         .unknown:
      rotation = 0
      imageOrientation = .up
    @unknown default:
      assertionFailure("Unknown orientation \(rawValue)")
      rotation = 0
      imageOrientation = .up
    }

    return (imageOrientation, rotation)
  }
}
