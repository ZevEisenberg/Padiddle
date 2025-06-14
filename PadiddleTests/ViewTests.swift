import XCTest

class ViewTests: XCTestCase {
  func testAccessibilityIdentifiers() {
    let view = UIView(axId: "foobar")
    XCTAssertEqual(view.accessibilityIdentifier, "foobar")

    let button = UIButton(type: .system, axId: "foobar")
    XCTAssertEqual(button.accessibilityIdentifier, "foobar")
  }
}
