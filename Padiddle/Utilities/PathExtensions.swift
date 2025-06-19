import CoreGraphics.CGPath

extension CGPath {
  // point smoothing from http://www.effectiveui.com/blog/2011/12/02/how-to-build-a-simple-painting-app-for-ios/
  static func smoothedPathSegment(points: [CGPoint]) -> CGPath {
    assert(points.count == 4)

    let p0 = points[0]
    let p1 = points[1]
    let p2 = points[2]
    let p3 = points[3]

    let c1 = CGPoint(
      x: (p0.x + p1.x) / 2.0,
      y: (p0.y + p1.y) / 2.0
    )
    let c2 = CGPoint(
      x: (p1.x + p2.x) / 2.0,
      y: (p1.y + p2.y) / 2.0
    )
    let c3 = CGPoint(
      x: (p2.x + p3.x) / 2.0,
      y: (p2.y + p3.y) / 2.0
    )

    let len1 = sqrt(pow(p1.x - p0.x, 2.0) + pow(p1.y - p0.y, 2.0))
    let len2 = sqrt(pow(p2.x - p1.x, 2.0) + pow(p2.y - p1.y, 2.0))
    let len3 = sqrt(pow(p3.x - p2.x, 2.0) + pow(p3.y - p2.y, 2.0))

    let divisor1 = len1 + len2
    let divisor2 = len2 + len3

    let k1 = len1 / divisor1
    let k2 = len2 / divisor2

    let m1 = CGPoint(
      x: c1.x + (c2.x - c1.x) * k1,
      y: c1.y + (c2.y - c1.y) * k1
    )
    let m2 = CGPoint(
      x: c2.x + (c3.x - c2.x) * k2,
      y: c2.y + (c3.y - c2.y) * k2
    )

    let smoothValue = CGFloat(1.0)
    let ctrl1: CGPoint = {
      let x = m1.x + (c2.x - m1.x) * smoothValue + p1.x - m1.x
      let y = m1.y + (c2.y - m1.y) * smoothValue + p1.y - m1.y
      return CGPoint(x: x, y: y)
    }()
    let ctrl2: CGPoint = {
      let x = m2.x + (c2.x - m2.x) * smoothValue + p2.x - m2.x
      let y = m2.y + (c2.y - m2.y) * smoothValue + p2.y - m2.y
      return CGPoint(x: x, y: y)
    }()

    let pathSegment = CGMutablePath()
    pathSegment.move(to: points[1])
    pathSegment.addCurve(to: points[2], control1: ctrl1, control2: ctrl2)

    return pathSegment
  }
}
