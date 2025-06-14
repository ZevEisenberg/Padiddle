import CoreGraphics.CGBase

let twoPi = CGFloat(2.0 * .pi)
let bytesPerPixel: size_t = 4
let bitsPerComponent: size_t = 8

extension CGFloat {
  func closeEnough(to: CGFloat) -> Bool {
    let epsilon = CGFloat(0.0001)
    let closeEnough = abs(self - to) < epsilon
    return closeEnough
  }

  var reasonableValue: CGFloat {
    closeEnough(to: 0) ? 0 : self
  }
}
