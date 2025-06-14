import QuartzCore

extension CATransaction {
  static func performWithoutAnimation(_ block: () -> Void) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    block()
    CATransaction.commit()
  }
}
