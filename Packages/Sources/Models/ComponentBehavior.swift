/// How a single component of a color varies.
public enum ComponentBehavior: Hashable, Sendable {
  case thetaIncreasing
  case thetaIncreasingAndDecreasing
  case velocityOut
  case velocityIn
  case manual(Double)
}
