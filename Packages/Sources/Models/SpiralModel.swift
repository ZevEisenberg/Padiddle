import CoreGraphics.CGBase

public struct SpiralModel {
  var colorGenerator: ColorGenerator

  /// How large to render the spiral, in points.
  var size: CGSize

  /// start distance from center
  var startRadius: Double

  /// space between each loop
  var spacePerLoop: Double

  var thetaRange: ClosedRange<Double>
  var thetaStep: Double
  var lineWidth: Double

  public init(
    colorGenerator: ColorGenerator,
    size: CGSize,
    startRadius: Double,
    spacePerLoop: Double,
    thetaRange: ClosedRange<Double>,
    thetaStep: Double,
    lineWidth: Double
  ) {
    self.colorGenerator = colorGenerator
    self.size = size
    self.startRadius = startRadius
    self.spacePerLoop = spacePerLoop
    self.thetaRange = thetaRange
    self.thetaStep = thetaStep
    self.lineWidth = lineWidth
  }
}
