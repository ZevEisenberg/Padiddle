import UIKit

extension UIScreen {
  var longestSide: CGFloat {
    let width = bounds.width
    let height = bounds.height
    return max(width, height)
  }

  var shortestSide: CGFloat {
    let width = bounds.width
    let height = bounds.height
    return min(width, height)
  }
}
