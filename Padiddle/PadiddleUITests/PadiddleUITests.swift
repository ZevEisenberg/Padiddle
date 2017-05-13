//
//  PadiddleUITests.swift
//  PadiddleUITests
//
//  Created by Zev Eisenberg on 9/12/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import XCTest

class PadiddleUITests: XCTestCase {

    override func setUp() {
        super.setUp()

        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        XCUIDevice.shared().orientation = .portrait
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testToolbarStaysHiddenWhileRotating() {
        let app = XCUIApplication()

        let window = app.windows.element(boundBy: 0)
        XCTAssert(window.exists)

        let rootView = window.children(matching: .other).element(matching: .other, identifier: "root view")
        XCTAssert(rootView.exists)

        let toolbarViewControllerView = rootView.children(matching: .other).element(matching: .other, identifier: "toolbar view controller view")
        XCTAssert(toolbarViewControllerView.exists)

        let toolbar = toolbarViewControllerView.children(matching: .other).element(matching: .other, identifier: "toolbarView")
        XCTAssert(toolbar.exists)

        XCTAssert(window.frame.contains(toolbar.frame), "At the start, the toolbar is on screen")

        let recordButtonButton = app.buttons["recordButton"]
        recordButtonButton.tap()

        XCTAssertFalse(window.frame.contains(toolbar.frame), "After recording begins, the toolbar is hidden")

        XCUIDevice.shared().orientation = .landscapeRight
        XCUIDevice.shared().orientation = .portrait

        XCTAssertFalse(window.frame.contains(toolbar.frame), "After rotation, the toolbar remains hidden")

        recordButtonButton.tap()

        XCTAssertTrue(window.frame.contains(toolbar.frame), "Tapping the Record button again un-hides the toolbar")
    }

}
