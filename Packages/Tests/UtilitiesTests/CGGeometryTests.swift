import CoreGraphics
import RealModule
import Testing
import Utilities

@Suite
struct CGGeometryTests {
  let accuracy = 0.00001

  @Test
  func affineTransformAngle() {
    for inputAngle in stride(from: -2 * .pi, through: 2 * .pi, by: 0.01) {
      let transform = CGAffineTransform(rotationAngle: inputAngle)
      let derivedAngle = transform.angle

      #expect(derivedAngle.normalizedRadians.isApproximatelyEqual(to: inputAngle.normalizedRadians, absoluteTolerance: 1e-4))
    }
  }

  @Test
  func distanceBetweenPoints() {
    let p1 = CGPoint.zero
    #expect(Double(CGPoint.distanceBetween(p1, p1)).isApproximatelyEqual(to: 0.0, absoluteTolerance: accuracy))

    let p2 = CGPoint(x: 10, y: 10)
    let p3 = CGPoint(x: 13, y: 14)
    #expect(Double(CGPoint.distanceBetween(p2, p3)).isApproximatelyEqual(to: 5.0, absoluteTolerance: accuracy))

    let p4 = CGPoint(x: -8, y: -2000)
    let p5 = CGPoint(x: -13, y: -2012)
    #expect(Double(CGPoint.distanceBetween(p4, p5)).isApproximatelyEqual(to: 13.0, absoluteTolerance: accuracy))

    let p6 = CGPoint.zero
    let p7 = CGPoint(x: 1, y: sqrt(3))
    #expect(Double(CGPoint.distanceBetween(p6, p7)).isApproximatelyEqual(to: 2.0, absoluteTolerance: accuracy))
  }
}

extension BinaryFloatingPoint {
  /// https://stackoverflow.com/a/69021369/255489
  var normalizedRadians: Self {
    (truncatingRemainder(dividingBy: 2 * .pi) + (2 * .pi))
      .truncatingRemainder(dividingBy: 2 * .pi)
  }
}
