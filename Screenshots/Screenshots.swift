import XCTest

@MainActor
class Screenshots: XCTestCase {
  lazy var iPhone = UIDevice.current.userInterfaceIdiom == .phone

  override func setUp() async throws {
    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.

    let app = XCUIApplication()
    setupSnapshot(app)
    app.launch()

    XCUIDevice.shared.orientation = .portrait
  }

  func testTakeScreenshots() {
    snapshot("1")

    let app = XCUIApplication()

    let helpButton = app.buttons["helpButton"]
    XCTAssertTrue(helpButton.exists)
    helpButton.tap()

    // Some screenshots miss the load of the web view, resulting
    // in a blank screen. Sleep to make sure we get it.
    sleep(1)

    snapshot("2")

    // n.b. we used to check for the accessibility identifier of the nav bar, but we can't control that in SwiftUI, so it ends up defaulting to the localized name, which is no good for UI tests. Instead, infer the About screen by looking for its Close button.
    let doneButton = app.buttons["aboutViewClose"]
    XCTAssertTrue(doneButton.exists)

    if iPhone {
      doneButton.tap()
    } else {
      // n.b. Post-SwiftUI and iOS 26 rewrite, we could technically tap the close button here as well, but it's kinda nice to know this works too.
      let dismissRegion = app.otherElements["PopoverDismissRegion"]
      XCTAssertTrue(dismissRegion.exists)
      dismissRegion.tap()
    }

    app.buttons["colorButton"].tap()

    snapshot("3")
  }

  func testTakeLandscapeScreenshotForWebsite() {
    if UIDevice.current.userInterfaceIdiom == .pad {
      XCUIDevice.shared.orientation = .portrait
      XCUIApplication().buttons["colorButton"].tap()
    } else {
      XCUIDevice.shared.orientation = .landscapeLeft
    }

    snapshot("website")
  }
}
