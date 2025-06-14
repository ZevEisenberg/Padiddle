import UIKit

struct SpiralModel {
  let colorManager: ColorManager
  let size: CGSize
  let startRadius: CGFloat
  let spacePerLoop: CGFloat
  let thetaRange: ClosedRange<CGFloat>
  let thetaStep: CGFloat
  let lineWidth: CGFloat
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

    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)

    // spiral parameters
    let center = CGPoint(x: (size.width / 2) - 1, y: (size.height / 2) + 2)
    let a = startRadius // start distance from center
    let b = spacePerLoop // space between each loop

    let path = UIBezierPath()
    path.lineWidth = lineWidth
    path.lineCapStyle = .square
    path.lineJoinStyle = .round

    var oldTheta = thetaRange.lowerBound
    var newTheta = thetaRange.lowerBound
    mutableColorManager.theta = thetaRange.lowerBound
    mutableColorManager.radius = a

    var oldR = a + (b * oldTheta)
    var newR = a + (b * newTheta)

    var oldPoint = CGPoint.zero
    var newPoint = CGPoint.zero

    var oldSlope = CGFloat.greatestFiniteMagnitude
    var newSlope = CGFloat.leastNormalMagnitude

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
      newR = a + b * newTheta
      mutableColorManager.radius = newR

      oldPoint.x = newPoint.x
      oldPoint.y = newPoint.y
      newPoint.x = center.x + (newR * cos(newTheta))
      newPoint.y = center.y + (newR * sin(newTheta))

      // slope calculation
      // (b * sinΘ + (a + bΘ) * cosΘ) / (b * cosΘ - (a + bΘ) * sinΘ)
      let aPlusBTheta = a + (b * newTheta)
      if firstSlope {
        oldSlope = (b * sin(oldTheta) + aPlusBTheta * cos(oldTheta)) / (b * cos(oldTheta) - aPlusBTheta * sin(oldTheta))
        firstSlope = false
      } else {
        oldSlope = newSlope
      }
      newSlope = (b * sin(newTheta) + aPlusBTheta * cos(newTheta)) / (b * cos(newTheta) - aPlusBTheta * sin(newTheta))

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

    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return image!
  }
}
