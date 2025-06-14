import UIKit

extension UIView {
  convenience init(axId accessibilityIdentifier: String) {
    self.init()
    self.accessibilityIdentifier = accessibilityIdentifier
  }
}

extension UIButton {
  convenience init(type buttonType: UIButton.ButtonType, axId accessibilityIdentifier: String) {
    self.init(type: buttonType)
    self.accessibilityIdentifier = accessibilityIdentifier
  }
}
