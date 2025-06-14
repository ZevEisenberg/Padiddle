import CoreGraphics
import RealModule
import Testing

@testable import Padiddle

let accuracy = 0.00001

@Suite
struct GeometryTests {
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

  @Test
  func cgSizeMax() {
    let zeroMax = CGSize.max(.zero, .zero)
    #expect(zeroMax == .zero)

    #expect(CGSize.max(.zero, CGSize(width: 10, height: 20)) == CGSize(width: 10, height: 20))

    #expect(CGSize.max(CGSize(width: 10, height: 20), CGSize(width: 5, height: 30)) == CGSize(width: 10, height: 30))

    #expect(CGSize.max(CGSize(width: -10, height: -10), CGSize(width: -5, height: 8)) == CGSize(width: -5, height: 8))
  }

  @Test
  func centerSmallerRect() {
    let smallRect1 = CGRect(x: 0, y: 0, width: 10, height: 10)
    let largeRect1 = CGRect(x: 0, y: 0, width: 20, height: 20)

    let centered1 = largeRect1.centerSmallerRect(smallRect1)
    #expect(centered1 == CGRect(x: 5, y: 5, width: 10, height: 10))
  }
}
