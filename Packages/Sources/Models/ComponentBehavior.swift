/// How a single component of a color varies.
public enum ComponentBehavior {
  case thetaIncreasing
  case thetaIncreasingAndDecreasing
  case velocityOut
  case velocityIn
  case manual(Double)
}
