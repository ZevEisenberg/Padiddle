import UIKit

public enum SpiralImageMaker {
  public static func image(spiralModel: SpiralModel, scale: CGFloat) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = scale
    let image = UIGraphicsImageRenderer(size: spiralModel.size, format: format).image { _ in
      drawSpiralInGraphicsContext(spiralModel: spiralModel)
    }
    return image
  }
}

private func drawSpiralInGraphicsContext(
  spiralModel: SpiralModel
) {
  let size = spiralModel.size
  let startRadius = spiralModel.startRadius
  let spacePerLoop = spiralModel.spacePerLoop
  let thetaRange = spiralModel.thetaRange
  let thetaStep = spiralModel.thetaStep
  let lineWidth = spiralModel.lineWidth

  var coordinate = ColorGenerator.Coordinate()
  coordinate.maxRadius = size.width / 2

  // spiral parameters
  let center = CGPoint(x: (size.width / 2) - 1, y: (size.height / 2) + 2)

  let path = UIBezierPath()
  path.lineWidth = lineWidth
  path.lineCapStyle = .square
  path.lineJoinStyle = .round

  var oldTheta = thetaRange.lowerBound
  var newTheta = thetaRange.lowerBound
  coordinate.theta = thetaRange.lowerBound
  coordinate.radius = startRadius

  var oldR = startRadius + (spacePerLoop * oldTheta)
  var newR = startRadius + (spacePerLoop * newTheta)

  var oldPoint = CGPoint.zero
  var newPoint = CGPoint.zero

  var oldSlope = Double.greatestFiniteMagnitude
  var newSlope = Double.leastNormalMagnitude

  // move to the initial point outside the loop, because we do it
  // only the first time
  newPoint.x = center.x + (oldR * cos(oldTheta))
  newPoint.y = center.y + (oldR * sin(oldTheta))

  var firstSlope = true
  while oldTheta < (thetaRange.upperBound - thetaStep) {
    path.removeAllPoints()
    path.move(to: newPoint)

    oldTheta = newTheta
    newTheta += thetaStep
    coordinate.theta = newTheta

    oldR = newR
    newR = startRadius + spacePerLoop * newTheta
    coordinate.radius = newR

    oldPoint.x = newPoint.x
    oldPoint.y = newPoint.y
    newPoint.x = center.x + (newR * cos(newTheta))
    newPoint.y = center.y + (newR * sin(newTheta))

    // slope calculation
    if firstSlope {
      oldSlope = calculateSlope(startRadius: startRadius, spacePerLoop: spacePerLoop, theta: oldTheta)
      firstSlope = false
    } else {
      oldSlope = newSlope
    }
    newSlope = calculateSlope(startRadius: startRadius, spacePerLoop: spacePerLoop, theta: newTheta)

    var controlPoint = CGPoint.zero

    let oldIntercept = -(oldSlope * oldR * cos(oldTheta) - oldR * sin(oldTheta))
    let newIntercept = -(newSlope * newR * cos(newTheta) - newR * sin(newTheta))

    if let intersection = CGPoint.lineIntersection(m1: oldSlope, b1: oldIntercept, m2: newSlope, b2: newIntercept) {
      controlPoint = intersection
    } else {
      fatalError("lines are parallel")
    }

    controlPoint.x += center.x
    controlPoint.y += center.y

    path.addQuadCurve(to: newPoint, controlPoint: controlPoint)

    let color = spiralModel.colorGenerator.color(at: coordinate)
    UIColor(color).setStroke()

    if !(oldTheta < (thetaRange.upperBound - thetaStep)) {
      path.lineCapStyle = .round
    }
    path.stroke()
  }
}

/// Slope calculation. Factored out because the compiler wasn't happy about moving this inside a closure for the above image rendering.
///
///     (b * sinΘ + (a + bΘ) * cosΘ) / (b * cosΘ - (a + bΘ) * sinΘ)
private func calculateSlope(
  startRadius a: Double,
  spacePerLoop b: Double,
  theta: Double
) -> Double {
  let aPlusBTheta = a + (b * theta)
  let numerator = (b * sin(theta) + aPlusBTheta * cos(theta))
  let denominator = (b * cos(theta) - aPlusBTheta * sin(theta))
  return numerator / denominator
}

private extension CGPoint {
  static func lineIntersection(
    m1: CGFloat,
    b1: CGFloat,
    m2: CGFloat,
    b2: CGFloat
  ) -> CGPoint? {
    if m1 == m2 {
      // lines are parallel
      return nil
    }

    let returnX = (b2 - b1) / (m1 - m2)

    let returnY = m1 * returnX + b1

    return CGPoint(x: returnX, y: returnY)
  }
}
