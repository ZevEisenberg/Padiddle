import UIKit

struct SpiralModel {
  let colorManager: ColorManager
  let size: CGSize

  /// start distance from center
  let startRadius: Double

  /// space between each loop
  let spacePerLoop: Double
  let thetaRange: ClosedRange<Double>
  let thetaStep: Double
  let lineWidth: Double
}

enum SpiralImageMaker {
  static func image(spiralModel: SpiralModel) -> UIImage {
    let size = spiralModel.size
    let startRadius = spiralModel.startRadius
    let spacePerLoop = spiralModel.spacePerLoop
    let thetaRange = spiralModel.thetaRange
    let thetaStep = spiralModel.thetaStep
    let lineWidth = spiralModel.lineWidth

    var mutableColorManager = spiralModel.colorManager

    mutableColorManager.maxRadius = size.width / 2

    let format = UIGraphicsImageRendererFormat()
    format.opaque = false
    let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
      // spiral parameters
      let center = CGPoint(x: (size.width / 2) - 1, y: (size.height / 2) + 2)

      let path = UIBezierPath()
      path.lineWidth = lineWidth
      path.lineCapStyle = .square
      path.lineJoinStyle = .round

      var oldTheta = thetaRange.lowerBound
      var newTheta = thetaRange.lowerBound
      mutableColorManager.theta = thetaRange.lowerBound
      mutableColorManager.radius = startRadius

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
        mutableColorManager.theta = newTheta

        oldR = newR
        newR = startRadius + spacePerLoop * newTheta
        mutableColorManager.radius = newR

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

        let color = mutableColorManager.currentColor
        color.setStroke()

        if !(oldTheta < (thetaRange.upperBound - thetaStep)) {
          path.lineCapStyle = .round
        }
        path.stroke()
      }
    }
    return image
  }
}

/// Slope calculation. Factored out because the compiler wasn't happy about moving this inside a closure for the above image rendering.
///
///     (b * sinΘ + (a + bΘ) * cosΘ) / (b * cosΘ - (a + bΘ) * sinΘ)
func calculateSlope(
  startRadius a: Double,
  spacePerLoop b: Double,
  theta: Double
) -> Double {
  let aPlusBTheta = a + (b * theta)
  let numerator = (b * sin(theta) + aPlusBTheta * cos(theta))
  let denominator = (b * cos(theta) - aPlusBTheta * sin(theta))
  return numerator / denominator
}
