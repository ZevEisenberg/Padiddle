import CoreGraphics.CGBase

let twoPi = 2.0 * .pi
let bytesPerPixel: size_t = 4
let bitsPerComponent: size_t = 8

extension BinaryFloatingPoint {
  func closeEnough(to: Self) -> Bool {
    let epsilon = Self(0.0001)
    let closeEnough = abs(self - to) < epsilon
    return closeEnough
  }

  var reasonableValue: Self {
    closeEnough(to: 0) ? 0 : self
  }
}
