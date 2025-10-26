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
    dismissAppleIntelligenceNotification()

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

  func testTakeScreenshotForWebsite() {
    if !iPhone {
      let colorButton = XCUIApplication().buttons["colorButton"]
      XCTAssert(colorButton.exists)
      colorButton.tap()
    }

    dismissAppleIntelligenceNotification()
    snapshot("website")
  }
}

private extension Screenshots {
  func dismissAppleIntelligenceNotification() {
    let springboardApp = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let appleIntelligenceNotification = springboardApp/*@START_MENU_TOKEN@*/ .staticTexts["Time to experience the new personal intelligence system."]/*[[".otherElements[\"NotificationBody.TopAligned.originalMessage\"].staticTexts",".otherElements",".staticTexts[\"Time to experience the new personal intelligence system.\"]",".staticTexts[\"TextContent.Primary\"]"],[[[-1,3],[-1,2],[-1,1,1],[-1,0]],[[-1,3],[-1,2]]],[1]]@END_MENU_TOKEN@*/ .firstMatch

    var dismissAttempts = 0
    while appleIntelligenceNotification.exists {
      appleIntelligenceNotification.swipeUp()
      dismissAttempts += 1
      sleep(2)
      if dismissAttempts >= 5 {
        XCTFail("Attempted to dismiss Apple Intelligence \(dismissAttempts) times, which probably means something is not working")
      }
    }
  }
}
