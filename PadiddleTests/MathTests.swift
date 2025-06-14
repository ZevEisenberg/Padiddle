import XCTest

class MathTests: XCTestCase {
  func testCloseEnough() {
    XCTAssertTrue(CGFloat(0.00000001).closeEnough(to: 0))
    XCTAssertTrue(CGFloat(0.00000001).closeEnough(to: 0.00000002))
    XCTAssertFalse(CGFloat(1).closeEnough(to: 2))
    XCTAssertTrue(CGFloat(0).closeEnough(to: 0))
    XCTAssertTrue(CGFloat(1).closeEnough(to: 1))
    XCTAssertTrue(CGFloat(-1).closeEnough(to: -1))
    XCTAssertTrue(CGFloat(-0.00000001).closeEnough(to: 0.00000001))
  }

  func testReasonableValue() {
    XCTAssertEqual(CGFloat(0).reasonableValue, 0)
    XCTAssertEqual(CGFloat(1e-10).reasonableValue, 0)
    XCTAssertNotEqual(CGFloat(1e-2).reasonableValue, 0)
  }
}
