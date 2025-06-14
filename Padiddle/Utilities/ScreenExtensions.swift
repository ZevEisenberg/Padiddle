import UIKit

extension UIScreen {
  var longestSide: CGFloat {
    let width = UIScreen.main.bounds.width
    let height = UIScreen.main.bounds.height
    return max(width, height)
  }

  var shortestSide: CGFloat {
    let width = UIScreen.main.bounds.width
    let height = UIScreen.main.bounds.height
    return min(width, height)
  }
}
