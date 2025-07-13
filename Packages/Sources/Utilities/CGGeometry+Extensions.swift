import CoreGraphics.CGBase

public extension CGSize {
  static func square(sideLength: CGFloat) -> Self {
    CGSize(width: sideLength, height: sideLength)
  }
}

public extension CGAffineTransform {
  var angle: CGFloat {
    atan2(b, a)
  }
}
