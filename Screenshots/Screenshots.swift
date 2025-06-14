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

    if iPhone {
      let navBar = app.navigationBars["about padiddle"]
      XCTAssertTrue(navBar.exists)
      let doneButton = navBar.buttons["doneButton"]
      XCTAssertTrue(doneButton.exists)
      doneButton.tap()
    } else {
      let dismissRegion = XCUIApplication().otherElements["PopoverDismissRegion"]
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
