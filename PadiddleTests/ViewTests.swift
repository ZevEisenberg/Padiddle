import Testing
import UIKit

@Suite
@MainActor
struct ViewTests {
  @Test
  func accessibilityIdentifiers() {
    let view = UIView(axId: "foobar")
    #expect(view.accessibilityIdentifier == "foobar")

    let button = UIButton(type: .system, axId: "foobar")
    #expect(button.accessibilityIdentifier == "foobar")
  }
}
