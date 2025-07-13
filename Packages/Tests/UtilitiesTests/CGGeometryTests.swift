import CoreGraphics
import Numerics
import Testing
import Utilities

@Suite
struct CGGeometryTests {
  @Test
  func affineTransformAngle() {
    for inputAngle in stride(from: -2 * .pi, through: 2 * .pi, by: 0.01) {
      let transform = CGAffineTransform(rotationAngle: inputAngle)
      let derivedAngle = transform.angle

      #expect(derivedAngle.normalizedRadians.isApproximatelyEqual(to: inputAngle.normalizedRadians, absoluteTolerance: 1e-4))
    }
  }
}

extension BinaryFloatingPoint {
  /// https://stackoverflow.com/a/69021369/255489
  var normalizedRadians: Self {
    (truncatingRemainder(dividingBy: 2 * .pi) + (2 * .pi))
      .truncatingRemainder(dividingBy: 2 * .pi)
  }
}
